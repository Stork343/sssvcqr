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

From GitHub:

```r
install.packages("remotes")
remotes::install_github("Stork343/sssvcqr")
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

## Prior Art and Scope

`sssvcqr` is intended for users who need all three of the following in one
workflow:

- conditional quantile regression;
- spatially varying coefficient surfaces over observed locations; and
- exact global-versus-local selection of complete candidate coefficient
  surfaces.

Related R workflows cover adjacent tasks. `quantreg` provides global quantile
regression, `GWmodel` provides geographically weighted mean-regression tools,
`qgam` provides additive quantile GAMs, and `mgcv` provides a broad smooth
modeling framework. These packages are mature and should be preferred when
their model class matches the analysis goal. `sssvcqr` fills a narrower gap:
graph-smoothed local coefficient deviations with group-sparse selection under
quantile loss.

## Lifecycle

This package is in an initially stable research-software state. The exported
API is small, documented, and covered by smoke tests, but future releases may
add a formula interface, compiled linear algebra kernels, uncertainty
summaries, and grid-prediction helpers in response to reviewer and user
feedback.

## Release Status

This is a research-software release prepared for journal submission. The public
repository is available at <https://github.com/Stork343/sssvcqr>. Release
`v0.0.2` is the package version used by the JSS submission materials. The
repository includes a GitHub Actions R CMD check workflow, package vignettes,
smoke-test reproducibility scripts, a JOSS paper draft, and a small Lucas County
example data set. A software DOI can be added after the GitHub release is
archived with Zenodo.
