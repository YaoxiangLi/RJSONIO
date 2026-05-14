expect_json_roundtrip <- function(x, expected = x, toJSONArgs = list(),
                                  fromJSONArgs = list(), compare = identical) {
  encoded <- do.call(toJSON, c(list(x), toJSONArgs))
  actual <- do.call(fromJSON, c(list(encoded), fromJSONArgs))
  if (identical(compare, identical)) {
    expect_identical(actual, expected)
  } else {
    expect_true(isTRUE(compare(actual, expected)))
  }
  invisible(actual)
}
