# Reproducibility Materials

This directory is reserved for scripts that reproduce the simulation and
empirical analyses from the SS-SVCQR paper. These scripts are intentionally kept
outside the package API so that installing `sssvcqr` remains lightweight.

Expected structure:

- `simulation/`: synthetic experiments and benchmark scripts.
- `lucas-county/`: real-data preprocessing and empirical analysis scripts.

The current files are smoke tests and templates. Before journal submission,
replace or extend them with exact scripts that regenerate every table and figure
reported in the software paper or methodological paper.
