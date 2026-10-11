# VAR Inputs

This folder contains the minimal packaged VAR input retained in the formal replication package.

The active MATLAB workflow in `Code/run_all.m` reads:

- `monthly/Democratic_Republic_of_the_Congo.csv`

Sources of the non-NBS columns (see Table 2 of the paper):

- IMF Data Portal, `https://data.imf.org`: CPI (`COD.CPI._T.SRP_YOY_PCH_PA_PT.M`) and exchange rate (`COD.XDC_USD.PA_RT.M`), accessed `12 November 2025`; commodity export price index (`COD.CEPI_CTOTX_GDP.R_RW_IX.M`), accessed `6 October 2025`.
- Banque Centrale du Congo, history of policy-rate decisions: policy rate.
- Global Scale Nightlight Time Series Dataset (Najjar, 2024), `https://nightlight.eoatlas.org`, accessed `1 October 2025`: nighttime lights.

Series, citations, and licenses are given in the Data Availability section of the top-level [`README.md`](../../../../README.md) (dataset 15).
