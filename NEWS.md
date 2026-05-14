# RJSONIO 2.0.3

## Documentation

- Added package vignettes covering package overview, parsing, serialization,
  type mapping, customization, and connection/streaming workflows.
- Added pkgdown Articles navigation for the vignette suite.

# RJSONIO 2.0.2

## Documentation

- Refreshed the README with installation, quick-start, API stability, and
  development guidance.
- Added pkgdown website configuration and GitHub Pages workflow support.

## Testing

- Audited legacy `tests/*.R` scripts against the `testthat` suite and added
  missing compatibility coverage for sample data, parser callbacks, bundled
  UTF-8 fixtures, empty-vector list behavior, and S4 setup behavior.

# RJSONIO 2.0.1

## Testing

- Added `testthat` unit test support for the public package API.
- Added compatibility tests for parsing, serialization, round trips,
  simplification behavior, encodings, connections, edge cases, and string
  callbacks to help preserve API stability for downstream packages.

# RJSONIO 2.0.0

## Maintainer handover

- With thanks to the CRAN team for looking after `RJSONIO`, Yaoxiang Li offered
  to help maintain the package after CRAN asked downstream package maintainers
  for a new maintainer.
- The handover followed the CRAN email thread from March 24 to April 5, 2025:
  CRAN asked for a new maintainer, Yaoxiang Li offered to help, CRAN accepted,
  and the package metadata was updated for the new release.
- This release records the maintainer transition and establishes a public
  GitHub source repository for ongoing CRAN maintenance.
