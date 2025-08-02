CREATE DATABASE Stock_Market;

USE Stock_Market;

CREATE TABLE Final_Data(
Ticker VARCHAR(50),
`Date` DATE NOT NULL,
`Close` FLOAT NOT NULL,
High FLOAT NOT NULL,
Low FLOAT NOT NULL,
`Open` FLOAT NOT NULL,
Volume BIGINT NOT NULL
);

SELECT * FROM Final_Data;

CREATE TABLE Company(
Company_ID INT AUTO_INCREMENT PRIMARY KEY,
Ticker VARCHAR(50) NOT NULL
);

INSERT INTO Company(Ticker)
SELECT DISTINCT Ticker FROM Final_Data;

SELECT * FROM Company;

CREATE TABLE Stock_Price(
Price_ID INT AUTO_INCREMENT PRIMARY KEY,
Company_ID INT NOT NULL,
Price_Date DATE NOT NULL,
Price_Close FLOAT NOT NULL,
Price_High FLOAT NOT NULL,
Price_Low FLOAT NOT NULL,
Price_Open FLOAT NOT NULL,
Price_Volume BIGINT NOT NULL,
FOREIGN KEY(Company_ID) REFERENCES Company(Company_ID)
);

INSERT INTO Stock_Price(Company_ID, Price_Date, Price_Close, Price_High, Price_Low, Price_Open, Price_Volume)
SELECT
	C.Company_ID,
	FD.`Date`,
	FD.`Close`,
	FD.High,
	FD.Low,
	FD.`Open`,
	FD.Volume
FROM Final_Data FD JOIN Company C
ON FD.Ticker = C.Ticker;

SELECT * FROM Stock_Price;

-- Is the company with the highest average close also stable and consistently high?
SELECT 
    c.Ticker,
    ROUND(AVG(sp.Price_Close), 4) AS AVG_Close,
    ROUND(STD(sp.Price_Close), 4) AS STD_DEV_Close,
    MIN(sp.Price_Close) AS MIN_Close,
    MAX(sp.Price_Close) AS MAX_Close
FROM Stock_Price sp
JOIN Company c ON sp.Company_ID = c.Company_ID
GROUP BY c.Ticker
ORDER BY c.Ticker ASC;
/*
Based on the analysis of average closing price and standard deviation per stock:
Microsoft and TSMC are the most stable companies with strong and consistent average closing prices. These are ideal for long-term, low-risk investors.
Companies like Amazon, Apple, and Meta Platforms show high average prices but with significant volatility, 
making them better suited for investors who can tolerate some risk for potential high returns.
Tesla, Nvidia, and Eli Lilly are highly volatile stocks. Their prices surged dramatically from very low starting points, 
indicating huge profit potential—but at the cost of stability. These are best for active traders or high-risk investors.
Berkshire Hathaway has the highest average price with notable fluctuations. It’s suitable for long-term investors who trust in the company's future growth.
*/

-- Which company had the highest stock price growth over the period?
WITH Ranked_Prices AS (
    SELECT
        sp.Company_ID,
        c.Ticker,
        sp.Price_Date,
        sp.Price_Close,
        FIRST_VALUE(sp.Price_Close) OVER (PARTITION BY sp.Company_ID ORDER BY sp.Price_Date) AS First_Close,
        LAST_VALUE(sp.Price_Close) OVER (PARTITION BY sp.Company_ID ORDER BY sp.Price_Date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS Last_Close
    FROM Stock_Price sp
    JOIN Company c ON sp.Company_ID = c.Company_ID
)
SELECT 
    Ticker,
    MIN(First_Close) AS First_Price,
    MAX(Last_Close) AS Last_Price,
    ROUND(MAX(Last_Close - First_Close), 4) AS Price_Growth,
    ROUND(((MAX(Last_Close) - MIN(First_Close)) / MIN(First_Close)) * 100, 2) AS Growth_Percentage
FROM Ranked_Prices
GROUP BY Ticker
ORDER BY Growth_Percentage DESC;
/*
NVIDIA’s stock showed explosive growth over the period, increasing by over 27,000%, far surpassing all other companies.
This points to a massive expansion in value and investor interest in recent years.
Tesla follows with over 2,600%, and the rest fall between 600%–1300%.
*/

-- What were the highest trading volume days for each company?
WITH Ranked_Volume AS (
    SELECT
        sp.Company_ID,
        c.Ticker,
        sp.Price_Date,
        sp.Price_Volume,
        RANK() OVER (PARTITION BY sp.Company_ID ORDER BY sp.Price_Volume  DESC) AS Volume_Rank
    FROM Stock_Price sp
    JOIN Company c ON sp.Company_ID = c.Company_ID
)
SELECT 
    Ticker,
    Price_Date,
    Price_Volume
FROM Ranked_Volume
WHERE Volume_Rank = 1
ORDER BY Price_Volume DESC;
/*
Peak trading volume days typically align with major financial events: earnings releases, market crashes, big announcements.
*/

-- Which companies experienced price increases despite decreasing trading volume?
WITH Price_Volume_Trend AS (
    SELECT
        c.Ticker,
        FIRST_VALUE(sp.Price_Close) OVER (PARTITION BY c.Ticker ORDER BY sp.Price_Date) AS First_Price,
        LAST_VALUE(sp.Price_Close) OVER (PARTITION BY c.Ticker ORDER BY sp.Price_Date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS Last_Price,
        FIRST_VALUE(sp.Price_Volume) OVER (PARTITION BY c.Ticker ORDER BY sp.Price_Date) AS First_Volume,
        LAST_VALUE(sp.Price_Volume) OVER (PARTITION BY c.Ticker ORDER BY sp.Price_Date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS Last_Volume
    FROM Stock_Price sp
    JOIN Company c ON sp.Company_ID = c.Company_ID
)
SELECT 
    Ticker,
    MIN(First_Price) AS First_Price,
    MAX(Last_Price) AS Last_Price,
    ROUND((MAX(Last_Price) - MIN(First_Price)) / MIN(First_Price) * 100, 2) AS Price_Growth_PCT,
    MIN(First_Volume) AS First_Volume,
    MAX(Last_Volume) AS Last_Volume,
    ROUND((MAX(Last_Volume) - MIN(First_Volume)) / MIN(First_Volume) * 100, 2) AS Volume_Growth_PCT
FROM Price_Volume_Trend
GROUP BY Ticker
HAVING 
    MAX(Last_Price) > MIN(First_Price) -- price went up
    AND MAX(Last_Volume) < MIN(First_Volume) -- volume went down
ORDER BY Price_Growth_PCT DESC;
/*
Despite a significant decrease in trading volume, stocks like Eli Lilly, Apple, Microsoft, and Amazon have shown explosive price growth.
This pattern indicates possible stealth accumulation, where long-term investors gradually build positions without causing noticeable volume spikes.
*/

-- Do any stocks show seasonal price trends, like consistent gains or drops in specific months?
SELECT 
    c.Ticker,
    MONTH(sp.Price_Date) AS month,
    ROUND(AVG(sp.Price_Close), 2) AS AVG_Monthly_Close
FROM Stock_Price sp
JOIN Company c ON sp.Company_ID = c.Company_ID
GROUP BY c.Ticker, MONTH(sp.Price_Date)
ORDER BY c.Ticker, month;
/*
Most companies show a clear seasonal pattern where average closing prices tend to rise steadily throughout the year, 
peaking in the last quarter (October to December). This suggests strong end-of-year performance, likely driven by consumer spending, 
product launches, or institutional investments.Some companies like Berkshire Hathaway remain stable throughout, reflecting long-term investor behavior.
*/






