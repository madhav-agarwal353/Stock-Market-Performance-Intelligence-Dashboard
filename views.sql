DROP VIEW IF EXISTS v_returns; DROP VIEW IF EXISTS v_yearly; DROP VIEW IF EXISTS v_monthly; DROP VIEW IF EXISTS v_sector_monthly;
CREATE VIEW v_returns AS
SELECT date, symbol, open, high, low, close, volume, turnover,
       close/LAG(close) OVER (PARTITION BY symbol ORDER BY date)-1 AS ret FROM prices;
CREATE VIEW v_yearly AS
WITH y AS (SELECT symbol, strftime('%Y',date) yr, close, volume, turnover,
  FIRST_VALUE(close) OVER (PARTITION BY symbol,strftime('%Y',date) ORDER BY date) f,
  LAST_VALUE(close) OVER (PARTITION BY symbol,strftime('%Y',date) ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) l FROM prices)
SELECT symbol, yr, MAX(l)/MAX(f)-1 AS yearly_return, AVG(volume) AS avg_volume, SUM(turnover) AS total_turnover FROM y GROUP BY symbol, yr;
CREATE VIEW v_monthly AS
WITH m AS (SELECT symbol, strftime('%Y-%m',date) ym, volume, turnover,
  LAST_VALUE(close) OVER (PARTITION BY symbol,strftime('%Y-%m',date) ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) me FROM prices),
e AS (SELECT symbol, ym, MAX(me) month_close, SUM(turnover) turnover, AVG(volume) avg_volume FROM m GROUP BY symbol, ym)
SELECT symbol, ym, month_close, turnover, avg_volume,
       month_close/LAG(month_close) OVER (PARTITION BY symbol ORDER BY ym)-1 AS month_ret FROM e;
CREATE VIEW v_sector_monthly AS
SELECT c.industry, m.ym, AVG(m.month_ret) AS avg_return, SUM(m.turnover) AS turnover, COUNT(*) AS n_stocks
FROM v_monthly m JOIN companies c USING(symbol) WHERE m.month_ret IS NOT NULL GROUP BY c.industry, m.ym;
