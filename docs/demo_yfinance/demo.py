import yfinance as yf

t = yf.Ticker("AAPL")

info = t.info
income = t.financials
balance = t.balance_sheet

snapshot = {
    "Currency": info.get("currency"),
    "Market Cap": info.get("marketCap"),
    "PE Ratio": info.get("trailingPE"),
    "Price/Book": info.get("priceToBook"),
    "Revenue": income.loc["Total Revenue"].iloc[0],
    "Net Income": income.loc["Net Income"].iloc[0],
    "Total Assets": balance.loc["Total Assets"].iloc[0],
}

print(snapshot)