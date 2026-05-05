\name{plot.sssvcqr}
\alias{plot.sssvcqr}
\title{Plot an SS-SVCQR fit}
\description{
Displays spatial deviation maps, local coefficient maps, residual maps, or ADMM
convergence traces for a fitted SS-SVCQR model.
}
\usage{
\method{plot}{sssvcqr}(x, type = c("deviation", "coefficient", "residual",
  "convergence"), index = 1L, ...)
}
\arguments{
\item{x}{A fitted \code{sssvcqr} object.}
\item{type}{Plot type.}
\item{index}{Index of the candidate local covariate for deviation and local
coefficient plots.}
\item{...}{Additional graphical arguments passed to \code{\link[graphics]{plot}}.}
}
\value{The input object, invisibly.}
\examples{
dat <- simulate_sssvcqr_data(n = 30, q = 1, p = 2, seed = 2)
fit <- ss_svcqr(dat$y, dat$Z, dat$X, dat$u,
  lambda1 = 2, lambda2 = 1, k_nn = 5,
  control = list(max_iter = 20, warn_nonconvergence = FALSE))
plot(fit, type = "deviation", index = 1)
}
