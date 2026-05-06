# sssvcqr 0.0.2

- Strengthened input validation, fold-wise adaptive-weight estimation in
  blocked cross-validation, and inverse-distance extrapolation for
  `predict(..., k > 1)`.
- Added a reproducible comparison section for the JSS replication material.

# sssvcqr 0.0.1

- Initial package scaffold for sparse-smooth spatially varying coefficient
  quantile regression.
- Added ADMM fitting, prediction, spatially blocked cross-validation, graph
  construction, simulation helpers, and KKT diagnostics.
- Added tests, vignettes, a Lucas County sample data set, CI configuration,
  contribution guidelines, and a JOSS paper draft.
- Added a standard `plot()` method for fitted model objects in line with JSS
  expectations for R packages returning compound objects.
