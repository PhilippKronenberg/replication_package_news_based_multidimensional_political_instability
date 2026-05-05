# Caldara and Iacoviello 2022 External Code

This folder contains the external supplementary code base used by the package MATLAB workflow.

The folder is kept under `Code/external/` because it is support material for the MATLAB replication workflow rather than part of the canonical R workflow documented in `Code/main.R`.

The package-level MATLAB entrypoint is now:

- `../../run_all.m`

That wrapper runs the external code from `var_results/` and refreshes the IRF figures used in this replication package.

The generated `var_results/estimate_monthly/` cache is not kept as a fixed package artifact. It is recreated when `../../run_all.m` is executed.
