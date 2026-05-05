\name{kkt_sssvcqr}
\alias{kkt_sssvcqr}
\title{KKT diagnostics for an SS-SVCQR fit}
\description{
Computes first-order diagnostic quantities for fitted SS-SVCQR coefficients,
including group stationarity residuals and zero-group margins.
}
\usage{
kkt_sssvcqr(y, Z, X, fit, L_sym = NULL, D_vec = NULL,
  components_list = NULL, lambda1 = fit$lambda1, lambda2 = fit$lambda2,
  w = fit$weights, tau = fit$tau)
}
\arguments{
\item{y, Z, X}{Model inputs used for fitting.}
\item{fit}{A fitted \code{sssvcqr} object.}
\item{L_sym, D_vec, components_list}{Optional graph quantities. If omitted,
they are rebuilt from the fitted object's graph metadata.}
\item{lambda1, lambda2, w, tau}{Penalty, weight, and quantile settings.}
}
\value{
A list with gradient norms, group stationarity residuals, group margins, group
norms, and the maximum diagnostic violation.
}
