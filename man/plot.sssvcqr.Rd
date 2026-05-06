\name{plot.sssvcqr}
\alias{plot.sssvcqr}
\title{Plot an SS-SVCQR fit}
\description{
Displays spatial deviation maps, local coefficient maps, residual maps, or ADMM
convergence traces for a fitted SS-SVCQR model. Spatial maps use a diverging
blue-white-red scale with a numeric colorbar.
}
\usage{
\method{plot}{sssvcqr}(x, type = c("deviation", "coefficient", "residual",
  "convergence"), index = 1L, ...)
}
\arguments{
\item{x}{A fitted \code{sssvcqr} object.}
\item{type}{Plot type. \code{"deviation"} displays the estimated spatial
deviation \code{delta[, index]}; \code{"coefficient"} displays the local total
coefficient \code{beta_spatial[, index]}; \code{"residual"} displays response
minus fitted conditional quantile; and \code{"convergence"} displays ADMM
primal and dual residual traces.}
\item{index}{Index of the candidate local covariate for deviation and local
coefficient plots. It is ignored for residual and convergence plots.}
\item{...}{Additional graphical arguments passed to \code{\link[graphics]{plot}}.}
}
\value{The input object, invisibly.}
\details{
For spatial plot types, the horizontal and vertical axes are the first two
columns of \code{x$u}. These are the coordinates supplied to
\code{\link{ss_svcqr}} when the model was fitted, so they may be raw coordinates
or scaled coordinates depending on the user's input. Blue colors represent
smaller values, white colors are near the middle of the displayed range, and
red colors represent larger values. The colorbar reports the numeric scale for
the plotted quantity. The convergence plot keeps a line legend for the four
ADMM residual traces instead of a colorbar.
}
\examples{
dat <- simulate_sssvcqr_data(n = 30, q = 1, p = 3, seed = 2)
fit <- ss_svcqr(dat$y, dat$Z, dat$X, dat$u,
  lambda1 = 5, lambda2 = 0.1, k_nn = 5,
  control = list(max_iter = 20, warn_nonconvergence = FALSE))
plot(fit, type = "deviation", index = 1)
plot(fit, type = "coefficient", index = 1)
plot(fit, type = "residual")
plot(fit, type = "convergence")
}
