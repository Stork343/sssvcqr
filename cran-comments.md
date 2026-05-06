## Initial submission

This is a draft CRAN submission note for the current local submission
candidate. It should be reviewed again after the final source tarball is built.

## R CMD check results

Local checks were run on macOS Sequoia 15.5, Apple silicon, with R 4.5.2.
The current local candidate declares version 0.0.3.

The source package was built with:

```r
R CMD build sssvcqr
```

The source package was checked with:

```r
R CMD check --no-manual --as-cran sssvcqr_0.0.3.tar.gz
```

The check completed with 0 errors, 0 warnings, and 2 notes:

- New submission.
- Unable to verify current time.

The check log is in `../sssvcqr.Rcheck/00check.log` in the local working tree.

No CRAN submission has been made from this local candidate yet.

## Package name

The package name `sssvcqr` was checked against the current CRAN package list on
2026-05-05 and was not present.

## Downstream dependencies

There are no downstream dependencies because this is a new package.
