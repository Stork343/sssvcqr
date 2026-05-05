## Initial submission

This is an initial CRAN submission.

## R CMD check results

Local checks were run on macOS Sequoia 15.5, Apple silicon, with
R 4.5.2.

The source package passes:

```r
R CMD check --no-manual sssvcqr_0.0.1.tar.gz
```

with status: OK.

The source package also passes:

```r
R CMD check --as-cran sssvcqr_0.0.1.tar.gz
```

except for local environment notes caused by missing external validation tools
on the maintainer machine:

- README.md or NEWS.md cannot be checked without pandoc.
- HTML validation is skipped because the installed HTML Tidy is not recent
  enough.

The remaining CRAN incoming note is expected for a first submission:

- New submission.

## Package name

The package name `sssvcqr` was checked against the current CRAN package list on
2026-05-05 and was not present.

## Downstream dependencies

There are no downstream dependencies because this is a new package.

