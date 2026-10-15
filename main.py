import sqlite3, numpy as np, pandas as pd
AF, RF = 248, 0.065
PRICES, META = "data/NIFTY50_all.csv", "data/stock_metadata.csv"   # Kaggle: rohanrao/nifty50-stock-market-data

# ---------- ETL -> SQLite ----------
con = sqlite3.connect("data/stocks.db"); con.executescript(open("schema.sql").read())
for t in ("prices","companies"): con.execute(f"DELETE FROM {t}")
df = pd.read_csv(PRICES, parse_dates=["Date"]).drop_duplicates(["Date","Symbol"])
p = df[["Date","Symbol","Open","High","Low","Close","Volume","Turnover"]].dropna(subset=["Close"])
p.columns = ["date","symbol","open","high","low","close","volume","turnover"]
p["date"] = p["date"].dt.strftime("%Y-%m-%d"); p.to_sql("prices", con, if_exists="append", index=False)
try:
    m = pd.read_csv(META)[["Symbol","Company Name","Industry"]]; m.columns = ["symbol","company","industry"]
except Exception: m = pd.DataFrame(columns=["symbol","company","industry"])
m = pd.DataFrame({"symbol":p["symbol"].unique()}).merge(m.drop_duplicates("symbol"), on="symbol", how="left")
m["company"] = m["company"].fillna(m["symbol"]); m["industry"] = m["industry"].fillna("OTHER")
m.to_sql("companies", con, if_exists="append", index=False)
con.executescript(open("views.sql").read()); con.commit()

# ---------- SQL -> analytics ----------
d = pd.read_sql("SELECT r.*, c.industry FROM v_returns r JOIN companies c USING(symbol) ORDER BY symbol, date", con)
g = d.groupby("symbol")
d["vol30"] = g["ret"].transform(lambda s: s.rolling(30).std()*np.sqrt(AF))
d["vol_ma20"] = g["volume"].transform(lambda s: s.rolling(20).mean())
d["vol_spike"] = d["volume"]/d["vol_ma20"]
d["drawdown"] = d["close"]/g["close"].cummax()-1
d["mkt_ret"] = d.groupby("date")["ret"].transform("mean")

def summ(x):
    r = x["ret"].dropna(); yrs = max((pd.to_datetime(x["date"].iloc[-1])-pd.to_datetime(x["date"].iloc[0])).days/365.25, 1e-9)
    tr = x["close"].iloc[-1]/x["close"].iloc[0]-1; mk = x.loc[r.index,"mkt_ret"]
    return pd.Series({"industry":x["industry"].iloc[0], "start":x["date"].iloc[0], "end":x["date"].iloc[-1],
        "total_return":tr, "cagr":(1+tr)**(1/yrs)-1, "ann_vol":r.std()*np.sqrt(AF),
        "sharpe":(r.mean()*AF-RF)/(r.std()*np.sqrt(AF)), "max_drawdown":x["drawdown"].min(),
        "ret_1y":x["close"].iloc[-1]/x["close"].iloc[-min(AF,len(x))]-1,
        "beta":np.cov(r,mk)[0,1]/np.var(mk,ddof=1), "avg_volume":x["volume"].mean(), "avg_turnover":x["turnover"].mean()})
S = d.groupby("symbol").apply(summ, include_groups=False).reset_index()
S["rank_return"] = S["total_return"].rank(ascending=False).astype(int)
sec = S.groupby("industry").agg(n_stocks=("symbol","count"), avg_total_return=("total_return","mean"), avg_cagr=("cagr","mean"),
        avg_vol=("ann_vol","mean"), avg_sharpe=("sharpe","mean"), avg_turnover=("avg_turnover","sum")).reset_index()
yr = pd.read_sql("SELECT y.*, c.industry FROM v_yearly y JOIN companies c USING(symbol)", con)
sm = pd.read_sql("SELECT * FROM v_sector_monthly", con)

# ---------- Save back to SQL + Power BI CSVs ----------
for name, t in {"fact_daily":d, "summary_stock":S, "summary_sector":sec}.items(): t.to_sql(name, con, if_exists="replace", index=False)
con.commit()
d.drop(columns=["mkt_ret","vol_ma20"]).to_csv("powerbi/fact_daily.csv", index=False)
S.to_csv("powerbi/summary_stock.csv", index=False); sec.to_csv("powerbi/summary_sector.csv", index=False)
yr.to_csv("powerbi/yearly.csv", index=False); sm.to_csv("powerbi/sector_monthly.csv", index=False); m.to_csv("powerbi/dim_company.csv", index=False)
print(S.sort_values("total_return", ascending=False).head(5)[["symbol","industry","total_return","ann_vol","sharpe"]])
print(sec.round(3))
