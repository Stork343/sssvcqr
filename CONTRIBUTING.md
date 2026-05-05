# Contributing

This repository is being prepared as research software for SS-SVCQR. Issues,
bug reports, reproducibility problems, documentation improvements, and small
test cases are welcome.

## Development Workflow

1. Install package dependencies listed in `DESCRIPTION`.
2. Run the unit tests:

   ```r
   testthat::test_local()
   ```

3. Run the package check before submitting changes:

   ```sh
   R CMD build .
   R CMD check --no-manual sssvcqr_*.tar.gz
   ```

## Reporting Problems

Please include:

- R version and operating system.
- The exact function call or script that failed.
- A minimal reproducible example when possible.
- Any warning or error output.

## Scope

The package focuses on sparse-smooth spatially varying coefficient quantile
regression and closely related diagnostics, tuning, simulation, and examples.
Large reproduction scripts for the associated paper should stay under
`reproducibility/`, not inside the core package API.
