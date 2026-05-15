# RJSONIO

[![CRAN status](https://www.r-pkg.org/badges/version/RJSONIO)](https://CRAN.R-project.org/package=RJSONIO)
[![R-CMD-check](https://github.com/YaoxiangLi/RJSONIO/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/YaoxiangLi/RJSONIO/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/YaoxiangLi/RJSONIO/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/YaoxiangLi/RJSONIO/actions/workflows/pkgdown.yaml)

`RJSONIO` converts R objects to and from JSON. It provides a stable API for
serializing R vectors, lists, data frames, arrays, environments, and S4 objects,
and for reading JSON from strings, files, and connections.

The package is maintained as a compatibility-first JSON implementation for R.
Its main value is stable behavior for established R workflows, plus extension
points such as parser handlers, callbacks, S4 methods, connection parsing, and
custom serialization methods.

## Installation

Install the CRAN release:

```r
install.packages("RJSONIO")
```

Install the development version from GitHub:

```r
install.packages("remotes")
remotes::install_github("YaoxiangLi/RJSONIO")
```

## Quick Start

```r
library(RJSONIO)

x <- list(
  id = 1,
  name = "RJSONIO",
  values = c(1, 2, 3),
  active = TRUE
)

json <- toJSON(x, pretty = TRUE)
cat(json)

fromJSON(json)
```

Validate JSON before parsing:

```r
candidate <- toJSON(list(name = "RJSONIO", version = "2.0.5"))
isValidJSON(I(candidate))
```

Round-trip common R objects:

```r
value <- list(a = 1, b = c(TRUE, FALSE), c = c("x", "y"))
identical(fromJSON(toJSON(value)), value)
```

## When RJSONIO Fits

`RJSONIO` is a good fit when a project already depends on its parsing or
serialization behavior, or when code needs callback-based parsing, S4/object
serialization, or explicit control over JSON generation.

For new projects that mainly consume web APIs or tidy tabular JSON, compare the
available R JSON packages and choose the one whose mapping and performance
match the job. The package website includes a comparison-oriented benchmark
article and examples of RJSONIO's customization points.

## Compatibility

The unit test suite includes compatibility coverage for parsing, serialization,
simplification modes, encodings, connections, edge cases, and string callbacks.
Changes to existing behavior should be deliberate, tested, and described in
`NEWS.md`.

## Documentation

- Package website and articles: <https://yaoxiangli.github.io/RJSONIO/>
- CRAN page: <https://CRAN.R-project.org/package=RJSONIO>
- Issues: <https://github.com/YaoxiangLi/RJSONIO/issues>

## Development

Run the unit tests:

```r
testthat::test_local()
```

Run a package check:

```sh
R CMD build RJSONIO
R CMD check --no-manual RJSONIO_2.0.5.tar.gz
```

Optional benchmark scripts are kept under `benchmarks/`. They are intended for
local comparison work and are excluded from CRAN package builds.
