# sssvcqr 0.0.3

- Updated graph construction to use sparse k-nearest-neighbor matrices.
- Enforced degree-weighted centering constraints in the ADMM delta updates
  through sparse KKT solves.
- Added known-truth simulation outputs, selection-recovery summaries,
  expanded numerical tests, and improved plot colorbars.
- Added root-level JSS replication materials for synthetic, blocked-CV,
  comparison, and Lucas County sample examples.

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
