#' Lucas County Housing Sample
#'
#' A small sample derived from the Lucas County housing data used in the
#' empirical analysis. It is included for examples and tutorials only; full
#' reproduction scripts should use the complete data file from the paper's
#' reproducibility materials.
#'
#' @format A data frame with selected variables:
#' \describe{
#'   \item{log_price}{Log sale price.}
#'   \item{log_TLA}{Log total living area.}
#'   \item{log_lotsize}{Log lot size.}
#'   \item{age_scaled}{House age scaled by 100.}
#'   \item{age2_scaled}{Squared age scaled by 10000.}
#'   \item{longitude}{Longitude.}
#'   \item{latitude}{Latitude.}
#'   \item{sale_year}{Sale year.}
#' }
#' @source Sampled from the project data file `lucas_housing_clean.csv`.
"lucas_housing_sample"
