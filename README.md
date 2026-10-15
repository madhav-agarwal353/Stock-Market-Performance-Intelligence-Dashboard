# Stock Market Performance Intelligence Dashboard
**Stack:** Python (Pandas, NumPy) · SQL (SQLite, window functions, views) · Power BI

## Data
Kaggle `rohanrao/nifty50-stock-market-data` -> save `NIFTY50_all.csv` and `stock_metadata.csv` in `data/`.

## Run
pip install -r requirements.txt && python main.py

## Pipeline
- ETL: CSV -> `prices`, `companies` (SQLite)
- SQL views: daily returns, yearly, monthly, sector-monthly (`views.sql`)
- Python: vol30, volume spike, drawdown, CAGR, Sharpe, beta, sector rollups -> `fact_daily`, `summary_stock`, `summary_sector`
- Power BI: `powerbi/` (load.pq, measures.dax, DASHBOARD.md)
