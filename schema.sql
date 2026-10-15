CREATE TABLE IF NOT EXISTS companies(symbol TEXT PRIMARY KEY, company TEXT, industry TEXT);
CREATE TABLE IF NOT EXISTS prices(date TEXT, symbol TEXT, open REAL, high REAL, low REAL, close REAL, volume REAL, turnover REAL, PRIMARY KEY(date,symbol));
CREATE INDEX IF NOT EXISTS ix_prices_sym ON prices(symbol,date);
