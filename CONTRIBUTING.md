# Contributing to RJSONIO

Thanks for helping maintain `RJSONIO`.

## Development Setup

Install package development tools, then install dependencies from the package
root:

```r
install.packages(c("testthat", "knitr", "rmarkdown", "pkgdown"))
```

Run the test suite:

```r
testthat::test_local()
```

Build vignettes:

```r
tools::buildVignettes(dir = ".")
```

Build the pkgdown site:

```r
pkgdown::build_site()
```

Run a package check:

```sh
R CMD build .
R CMD check --as-cran RJSONIO_2.0.4.tar.gz
```

## Compatibility Expectations

`RJSONIO` is maintained with emphasis on stable behavior. Changes should keep
the existing public API working unless a behavior change is intentional,
tested, and documented in `NEWS.md`.

Before changing parser or writer behavior:

- add or update a focused `testthat` test;
- check existing legacy tests under `tests/`;
- run examples and vignettes;
- compare generated JSON before and after the change.

Performance changes are welcome when they preserve the current output for the
covered inputs.

## Benchmarks

Optional benchmark scripts live under `benchmarks/` and are excluded from CRAN
builds. Run them from the repository root:

```r
source("benchmarks/run-benchmarks.R")
```

The results are machine-specific and should be regenerated before making
performance claims in release notes.
