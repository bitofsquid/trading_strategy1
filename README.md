# trading_strategy1
Testing a trading strategy based on analyst optimism and investor behavioral biases.

## Introduction
An academic paper entitled ["Analyst Bias and Mispricing"](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2653666) by Mark Grinblatt, Gergana Jostova, and Alexander Philipov posits that stock analyst optimism can irrationally influence investor behavior and create predictable patterns in asset prices. Although Grinblatt et al exhaustively explore academic support for their thesis in the paper, the primary purpose of this project is to re-create portions of their analysis using real-world data in the hopes of verifying their findings. The following sections of this readme attempt to explain the approach and methodology used in carrying out this project. 

## Part 1: Data
In an effort to make this project reproducible by others, it largley relies on data from free and easy-to-obtain sources. In this repo, the first of two R scripts--[ts1_data.R](https://github.com/jtryker/trading_strategy1/blob/master/ts1_data.R)--focuses on data gathering while the second--[ts1_analysis.R](https://github.com/jtryker/trading_strategy1/blob/master/ts1_analysis.R)--concentrates on more formal analysis. 

### Establishing the investment universe
The investment universe for this project was limited to the largest 1,000 publicly-traded firms listed on US stock exchanges. The list of tickers for these companies was obtained from the University of Chicago's [Center for Research in Security Prices](http://www.crsp.com/indexes-pages/returns-and-constituents). The tickers used in this analysis were obtained as of November 30, 2016. All returns data were gathered on a monthly basis until this date as well. 

### Defining a time horizon and benchmark
Monthly ticker-level returns were calculated on adjusted closing prices from Yahoo via Jeffrey Ryan's `quantmod` package. Data spanning the last 20 years was gathered as this ensured multiple market cycles were included in the time series. The `quantmod` package was also used to obtain monthly returns for SPY, a popular stock market ETF designed to mimic the S&P 500 Index. Data on SPY was obtained for use as a benchmark against which risk and return characteristics could be measured. In addition, individual company market capitalizations as of November 30, 2016 were obtained by accessing the [Intrinio API](http://docs.intrinio.com/#u-s-public-company-data-feed) (Intrinio is a third party data vendor similar to [Quandl](https://www.quandl.com/about). *Note: The market capitilization data was not explicitly used in this analysis, but was gathered for potential future use.*

### Obtaining analyst estimates
Lastly, analyst estimates for current year earnings per share were sourced from Yahoo using a web scraping approach. The specific data obtained are the number of analysts covering each firm as well as their average, high and low estimates for earnings per share. Because Yahoo renders most of the financial data on its webpages using JavaScript, traditional implementations of web scraping proved inadequate. Hadley Wickham's `httr` and `rvest` packages were ultimately used to parse the HTML, but [PhantomJS](http://phantomjs.org/) (a "headless" web browser) and a bit of borrowed C code were required to eventually scrape the necessary data. As the author does not have an extensive background in computer programming, information found at the following links was instrumental in facilitating this portion of the ts1_data script (http://bit.ly/2icbLED and http://bit.ly/2ixAfsJ).

## Part 2: Analysis
The main conjecture of the paper referenced above is that excessive analyst optimism can lead to poor future performance for stocks. Furthermore, firms with difficult to forecast earnings can exacerbate this phenomenon. The paper suggests a market neutral trading strategy to exploit these occurences: Sell firms with high optimism and difficult to forecast earnings and buy firms with low optimism and "easy" to forecast earnings.

### Measuring analyst dispersion and optimism
In order to test these ideas, measures of dispersion and optimism were calculated for each ticker based on the average, high, and low estimates for each firm's earnings. The dispersion measure is meant to capture the total spread between high and low earnings estimates relative to the average while the optimism measure is meant to capture the magnitude of the spread between the average and high estimates relative to the average and low estimates. In other words, firms with a large spread between high and low estimates are assigned high dispersion ratings and firms with outsized high estimates (relative to low estimates) are assigned high optimism ratings. *Note that firms with fewer than 5 analyst estimates were excluded from this rating process.*

### Selecting firms and constructing portfolios
Based on these ratings, each firm was ranked from highest dispersion and highest optimism to lowest. The top and bottom 10 firms were then selected for investment and several portfolios constructed for use in analyzing simulated historical performance. The 10 firms with the highest dispersion and highest optimism were sold (labelled "Short") and the 10 firms with the lowest dispersion and optimism were bought (labelled "Long"). Long minus Short portfolios were also constructed as a theoretical representation of a market-neutral strategy (labelled "Long - Short"). To avoid timing problems, firms were only eligible for investment if they existed for the entire 20 year period used in this analysis. Brian Peterson and Peter Carl's `PortfolioAnalytics` package was used to construct mean-variance optimized portfolios (i.e. portfolios where weights were determined to optimize the Sharpe ratio). The `PerformanceAnalytics` package by the same authors was used to calculate equal-weighted portfolio returns. 

### Visualizing the results
**Exhibit 1** displays a boxplot of returns for each portfolio in order to generically visualize the distribution of returns.  From this information, we can see that the Long - Short portfolios appear to produce only modest expected (i.e. mean) returns at comparatively high levels of risk. Indeed, when each portfolio is viewed in a risk/return scatter plot this observation is all the more evident (**Exhibit 2**)--not very encouraging. For robustness, **Exhibit 3** displays cumulative returns, monthly returns, and drawdown for each mean-variance optimized portfolio via a convenient function of the 'PerformanceAnayltics' package. Although the optimized Long and Short portfolios individually appear to exhibit attractive cumulative performance, their combination does not. Furthermore, the optimized Long - Short portfolio significantly underperforms from a drawdown perspective.

### Conclusion
Based on the evidence presented in this analysis, it appears as though a market neutral trading strategy reliant on analyst optimism and dispersion has precarious potential for profitability. However, there are several reasons why adjustments to this analysis may change the results significantly. For example, long or short portfolios of only 10 stocks likely results in high levels of idiosyncratic risk. Perhaps including larger portfolios of stocks to long and short would produce more attractive results. Futhermore, this analysis likely exhibits some degree of survivorship bias as it only focuses on firms that remained actively listed on US stock exchanges for a 20 year period of time. It is possible that including firms that failed and were delisted during this period could significantly alter the results. Lastly, there were several other methodological shortcuts taken in this analysis for practical reasons (time, resources, etc.) that surely impacted this analysis as well. These are mentioned in the additional comments below. 

In all, this was an immensely enjoyable project to complete despite its limitations and the author looks forward to addressing its shortcomings in follow up analyses in the future. Thanks for reading.

![exhibit1](https://github.com/jtryker/trading_strategy1/blob/master/exhibit1.png)
![exhibit2](https://github.com/jtryker/trading_strategy1/blob/master/exhibit2.png)
![exhibit3](https://github.com/jtryker/trading_strategy1/blob/master/exhibit3.png)

## Additional comments

### Unrealistic assumptions and methodological shortcuts
The author recognizes that several simplifications were made in the analysis portion of this project. These simplifications were made largely because the project was designed to serve as a "proof of concept" and a basic foundation upon which further analysis could be conducted in the future. Some brief comments on a few main simplifications follows (these comments are not meant to be exhaustive):

Firstly, firm size and analyst earnings estimates were gathered as of one point in time (November 30, 2016) and were assumed to remain constant over the historical length of the project's time horizon. This is not a sound assumption as these data points would certainly have changed over time, but was made nonetheless for practical considerations. A more accurate treatment of analyst recommendations would likely have significant impact on the findings in this analysis and will be a key enhancement in any further research on this topic.

Secondly, the potential investment universe of firms was reduced from the initial 1,000 to roughly 603 as a result of limiting the opportunity set to firms with a 20 year history of returns. This approach excludes firms that may have failed during the observation period and result in survivorship bias.

Thirdly, rebalancing was only casually dealt with in the portfolio construction process. The `PortfolioAnalytics` package has additional capabilities that provide more realistic assumptions for portfolio rebalancing which include trading costs, etc. and could add robustness to future analyses.

Finally, although this analysis attempted to recreate the main conjecture of the original paper using real-world data, several other real-world factors were not considered in evaluating a market neutral trading strategy. Such factors include transaction costs (including any borrowing/margin costs associated with shorting) and slippage.

### Tips for using `PortfolioAnalytics`
The author found this (and its companion `PerformanceAnalytics` package) to be very helpful in this project. Despite this, the `PortfolioAnalytics` package itself proved a bit cumbersome to get started with. For those seeking to replicate this analysis, please take care to install *all* (optional and required) dependencies this package mentions in its documentation on CRAN. In addition, the following resources proved extremely helpful in getting started with the basics of the package effectively. Enjoy!!

https://www.r-bloggers.com/introduction-to-portfolioanalytics/
http://www.rinfinance.com/agenda/2014/workshop/RossBennett.pdf
http://www.rinfinance.com/agenda/2010/Carl+Peterson+Boudt_Tutorial.pdf
