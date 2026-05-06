\name{selection_recovery_table}
\alias{selection_recovery_table}
\title{Compare true and estimated spatial-deviation selection}
\description{
Builds a compact truth-versus-estimate table for synthetic examples generated
by \code{\link{simulate_sssvcqr_data}}.
}
\usage{
selection_recovery_table(fit, truth, tol = 1e-6)
}
\arguments{
\item{fit}{An \code{sssvcqr} fitted object returned by \code{\link{ss_svcqr}}.}
\item{truth}{A list containing \code{delta_true} and, optionally,
\code{active}. Objects returned by \code{\link{simulate_sssvcqr_data}} include
these entries.}
\item{tol}{Non-negative tolerance used to classify an estimated deviation field
as selected.}
}
\value{
A data frame with the covariate index, covariate name, true active status, true
deviation norm, estimated deviation norm, and selected active status.
}
\examples{
dat <- simulate_sssvcqr_data(n = 40, q = 1, p = 3, seed = 1)
fit <- ss_svcqr(dat$y, dat$Z, dat$X, dat$u,
  lambda1 = 5, lambda2 = 0.1, k_nn = 6,
  control = list(max_iter = 30, warn_nonconvergence = FALSE))
selection_recovery_table(fit, dat)
}
