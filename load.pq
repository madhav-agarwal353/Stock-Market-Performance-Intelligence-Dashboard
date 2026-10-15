// Parameter: DataPath (Text) = C:\path\to\stock_intel\powerbi\
// One blank query per block. Names: fact, dim_company, summary_stock, summary_sector, yearly, sector_monthly

// ---- fact ----
let S=Csv.Document(File.Contents(DataPath&"fact_daily.csv"),[Delimiter=",",Encoding=65001]), H=Table.PromoteHeaders(S),
T=Table.TransformColumnTypes(H,{{"date",type date},{"open",type number},{"high",type number},{"low",type number},{"close",type number},
{"volume",type number},{"turnover",type number},{"ret",type number},{"vol30",type number},{"vol_spike",type number},{"drawdown",type number}},"en-US") in T

// ---- dim_company ----
let S=Csv.Document(File.Contents(DataPath&"dim_company.csv"),[Delimiter=",",Encoding=65001]) in Table.PromoteHeaders(S)

// ---- summary_stock ----
let S=Csv.Document(File.Contents(DataPath&"summary_stock.csv"),[Delimiter=",",Encoding=65001]), H=Table.PromoteHeaders(S),
T=Table.TransformColumnTypes(H,{{"total_return",type number},{"cagr",type number},{"ann_vol",type number},{"sharpe",type number},
{"max_drawdown",type number},{"ret_1y",type number},{"beta",type number},{"avg_volume",type number},{"avg_turnover",type number},{"rank_return",Int64.Type}},"en-US") in T

// ---- summary_sector ----
let S=Csv.Document(File.Contents(DataPath&"summary_sector.csv"),[Delimiter=",",Encoding=65001]), H=Table.PromoteHeaders(S),
T=Table.TransformColumnTypes(H,{{"n_stocks",Int64.Type},{"avg_total_return",type number},{"avg_cagr",type number},{"avg_vol",type number},{"avg_sharpe",type number},{"avg_turnover",type number}},"en-US") in T

// ---- yearly ----
let S=Csv.Document(File.Contents(DataPath&"yearly.csv"),[Delimiter=",",Encoding=65001]), H=Table.PromoteHeaders(S),
T=Table.TransformColumnTypes(H,{{"yr",type text},{"yearly_return",type number},{"avg_volume",type number},{"total_turnover",type number}},"en-US") in T

// ---- sector_monthly ----
let S=Csv.Document(File.Contents(DataPath&"sector_monthly.csv"),[Delimiter=",",Encoding=65001]), H=Table.PromoteHeaders(S),
A=Table.AddColumn(H,"month",each Date.FromText([ym]&"-01"),type date),
T=Table.TransformColumnTypes(A,{{"avg_return",type number},{"turnover",type number},{"n_stocks",Int64.Type}},"en-US") in T
