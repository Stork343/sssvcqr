# sssvcqr

`sssvcqr` implements sparse-smooth spatially varying coefficient quantile
regression (SS-SVCQR). The model decomposes each candidate spatial coefficient
into a global baseline and a location-specific deviation, selects global versus
local effects with a group penalty, and smooths local deviations with a graph
Laplacian over observed spatial locations.

This package is an initial research-software version of the code used for the
paper *Sparse-Smooth Spatially Varying Coefficient Quantile Regression*.

## Installation

From the package directory:

```sh
R CMD INSTALL .
```

Or from the `extend/` directory:

```sh
R CMD INSTALL sssvcqr
```

## Quick Start

```r
library(sssvcqr)

dat <- simulate_sssvcqr_data(n = 80, q = 1, p = 2, seed = 1)

fit <- ss_svcqr(
  y = dat$y,
  Z = dat$Z,
  X = dat$X,
  u = dat$u,
  tau = 0.5,
  lambda1 = 2,
  lambda2 = 1,
  k_nn = 6,
  control = list(max_iter = 100, warn_nonconvergence = FALSE)
)

fit
summary(fit)
head(predict(fit))
```

Spatially blocked cross-validation:

```r
cv <- cv_ss_svcqr(
  y = dat$y,
  Z = dat$Z,
  X = dat$X,
  u = dat$u,
  tau = 0.5,
  lambda1_seq = c(1, 2),
  lambda2_seq = c(0.5, 1),
  K_folds = 3,
  control = list(max_iter = 50, warn_nonconvergence = FALSE)
)

cv$best
```

## Main Functions

- `ss_svcqr()`: fit SS-SVCQR by ADMM.
- `predict.sssvcqr()`: predict fitted quantiles at training or new locations.
- `cv_ss_svcqr()`: tune penalties by spatially blocked cross-validation.
- `build_graph_laplacian()`: construct a weighted k-nearest-neighbor graph and Laplacian.
- `simulate_sssvcqr_data()`: generate synthetic examples for testing and tutorials.
- `kkt_sssvcqr()`: compute first-order diagnostic quantities for a fitted model.

## Development Status

This is a package scaffold suitable for continued development. Before journal
submission, the project should add a public Git history, tagged releases, a DOI,
CI checks, vignettes reproducing the paper examples, and author-verified license
and citation metadata.

The repository now includes a GitHub Actions R CMD check workflow, package
vignettes, smoke-test reproducibility scripts, a JOSS paper draft, and a small
Lucas County example data set.
