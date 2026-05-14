# RJSONIO competitor benchmarks

This directory contains optional benchmark scripts for comparing `RJSONIO` with
direct JSON package competitors. These files are kept in the GitHub repository
but excluded from CRAN package builds.

Run the benchmark suite from the package root:

```r
source("benchmarks/run-benchmarks.R")
```

The script requires `bench` and `ggplot2`. Competitor packages are optional; a
missing package or unsupported operation is recorded in the skip table rather
than failing the whole run.

Outputs are written to:

- `benchmarks/results/benchmark-results.csv`
- `benchmarks/results/benchmark-skips.csv`
- `benchmarks/results/package-versions.csv`
- `benchmarks/figures/elapsed-time.png`
- `benchmarks/figures/memory-allocation.png`
- `benchmarks/figures/relative-time.png`

The plots are also copied to `vignettes/figures/benchmarks/` for the pkgdown
benchmark article. Benchmark results are machine-specific and should be rerun
before making release notes or performance claims.
