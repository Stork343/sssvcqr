candidate_inputs <- c(
  file.path("..", "..", "code", "data", "lucas_housing_clean.csv"),
  file.path("..", "..", "data", "lucas_housing_clean.csv"),
  file.path("..", "code", "data", "lucas_housing_clean.csv"),
  file.path("..", "data", "lucas_housing_clean.csv")
)
input <- candidate_inputs[file.exists(candidate_inputs)][1]
if (is.na(input)) {
  stop("Could not find lucas_housing_clean.csv")
}

set.seed(20260505)
full <- read.csv(input)
keep <- c(
  "log_price", "log_TLA", "log_lotsize", "age_scaled", "age2_scaled",
  "longitude", "latitude", "sale_year"
)
full <- full[stats::complete.cases(full[, keep]), keep]
idx <- sample(seq_len(nrow(full)), size = min(150L, nrow(full)))
lucas_housing_sample <- full[idx, ]
row.names(lucas_housing_sample) <- NULL

if (!dir.exists("data")) {
  dir.create("data")
}
save(lucas_housing_sample, file = file.path("data", "lucas_housing_sample.rda"))
