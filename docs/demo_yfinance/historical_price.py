import yfinance as yf

df = yf.download(
    "AAPL",
    start="2015-01-01",
    end="2024-12-31",
    interval="1d",
    auto_adjust=True,   # adjusts for splits & dividends
    progress=False
)

print(df.head())
print("---")
print(df.tail())
