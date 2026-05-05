---
title: "sssvcqr: Sparse-Smooth Spatially Varying Coefficient Quantile Regression in R"
tags:
  - R
  - quantile regression
  - spatial statistics
  - graph regularization
  - ADMM
authors:
  - name: Houjian Hou
    affiliation: 1
affiliations:
  - name: "Center for Applied Statistics, School of Statistics, Renmin University of China"
    index: 1
date: 5 May 2026
bibliography: paper.bib
---

# Summary

`sssvcqr` is an R package for sparse-smooth spatially varying coefficient
quantile regression. It estimates conditional quantiles in spatial data by
decomposing candidate local coefficients into a global baseline and a
location-specific deviation. A group penalty selects which covariates need
spatial deviations, while a graph Laplacian stabilizes the selected deviation
fields over irregularly sampled locations.

# Statement of Need

Spatial regression software often provides either global quantile regression or
local spatial smoothing, but practitioners also need a workflow that decides
which effects are spatially varying at a target quantile. `sssvcqr` targets
statisticians and applied researchers working with georeferenced outcomes,
heavy-tailed noise, heteroskedasticity, and interpretable global-local model
structure.

# State of the Field

Related R packages include `quantreg` for global quantile regression
[@koenker2005quantile], `GWmodel` for geographically weighted modeling
[@gollini2015gwmodel], and `qgam` for quantile generalized additive models
[@fasiolo2021qgam]. `sssvcqr` differs by combining quantile loss,
graph-Laplacian smoothing, and group-level global-versus-local selection in a
single convex objective.

# Software Design

The core API separates fitting, prediction, graph construction, spatially
blocked cross-validation, simulation, and diagnostic checks. The estimator is
implemented in R with sparse matrix operations from `Matrix`; graph construction
uses k-nearest-neighbor distances and `igraph` connected components. The main
solver uses ADMM so that the non-smooth check loss and group penalty can be
handled by proximal updates while the smoothness term remains a sparse linear
algebra problem.

# Research Impact

The package implements the method developed for the associated paper,
*Sparse-Smooth Spatially Varying Coefficient Quantile Regression*. The
repository includes simulation and Lucas County housing examples for verifying
the model workflow and preparing reproducible analyses. Before JOSS submission,
the public repository should include tagged releases, archived software DOI,
continuous integration results, and a public development history.

# AI Usage Disclosure

Draft package scaffolding, documentation, tests, and this paper draft were
prepared with assistance from OpenAI Codex. The human author remains responsible
for reviewing, editing, validating, and maintaining all software and manuscript
content, and for making the scientific and software design decisions.

# References
