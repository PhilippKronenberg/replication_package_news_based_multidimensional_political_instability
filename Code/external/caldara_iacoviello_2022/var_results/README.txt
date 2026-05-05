Readme file for the var_results directory

The file run_all.m reproduces the VAR results (Figures 9 and 10 and Figures A.5, A.6, A.7 in the Appendix) contained in the paper "Measuring Geopolitical Risk".

Input
-----
run_all.m (calls run_var_estimation.m, run_var_estimation_acts_threats.m, run_var_plot_figures.m)


Output
------
Figures 9 and 10a/10b in the paper
Figures A.5, A.6, A.7 in the appendix


Notes
-----
* Some of the labels in Figure A.7 have been manually adjusted for best fit on the printed page




SERIES MNEMONICS AS FOLLOWS.
DATA TRANSFORMATIONS are shown in the xlsx file.
DATA are pulled from csv file.
All series downloaded from Haver, except NFCI, taken from Fred.
Series downloaded on October 7, 2021.


1: SEPUI@USECON   [Economic Policy Uncertainty Index (1985-09=101.06535)]
2: FCM2@USECON   [2-Year Treasury Note Yield at Constant Maturity (% p.a.)]
3: PZTEXP@USECON   [Spot Oil Price: West Texas Intermediate [Prior'82=Posted Price] ($/Barrel)]
4: SPVXO@USECON   [CBOE Market Volatility Index: VOX, Old Method (Index)]
5: PCUN@USECON   [CPI-U: All Items (NSA, 1982-84=100)]
6: LHTPRIVA@USECON   [Aggregate Hours: Nonfarm Payrolls, Private Sector (SAAR, Bil.Hrs)]
7: FH@USECON   [Real Private Fixed Investment (SAAR, Bil.Chn.2012$)]
8: GDPH@USECON   [Real Gross Domestic Product (SAAR, Bil.Chn.2012$)]
9: LN16N@USECON   [Civilian Noninstitutional Population: 16 Years and Over (NSA, Thous)]
10: SP500@USECON   [Stock Price Index: Standard & Poor's 500 Composite  (1941-43=10)]
11: NFCI [Chicago Fed National Financial Conditions Index (https://fred.stlouisfed.org/series/NFCI)]


