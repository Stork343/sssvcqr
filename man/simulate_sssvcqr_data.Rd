\name{simulate_sssvcqr_data}
\alias{simulate_sssvcqr_data}
\title{Simulate data for SS-SVCQR examples}
\description{
Generates synthetic spatial quantile-regression data with known global
coefficients and sparse spatial deviation fields. For the default
\code{p = 3} design, the first and third deviation fields are active and the
second deviation field is exactly zero.
}
\usage{
simulate_sssvcqr_data(n = 120, q = 2, p = 3, tau = 0.5,
  noise_sd = 0.4, seed = NULL, graph_k = 8L)
}
\arguments{
\item{n}{Number of observations.}
\item{q}{Number of global covariates.}
\item{p}{Number of candidate spatially varying covariates.}
\item{tau}{Target quantile level.}
\item{noise_sd}{Gaussian error scale.}
\item{seed}{Optional random seed.}
\item{graph_k}{Graph size used to center true deviations with the same
degree-weighted connected-component convention used by the estimator.}
}
\value{A list containing \code{y}, \code{Z}, \code{X}, \code{u},
\code{eta}, \code{alpha_true}, \code{beta_G_true}, \code{delta_true},
\code{beta_spatial_true}, \code{active}, \code{tau}, and \code{seed}. The
legacy aliases \code{alpha}, \code{beta_G}, and \code{delta} are retained for
backward compatibility.}
\examples{
dat <- simulate_sssvcqr_data(n = 30, q = 1, p = 3, seed = 1)
str(dat)
dat$active
}
