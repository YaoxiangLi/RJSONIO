test_that("simple atomic values round trip through JSON", {
  expect_json_roundtrip(c(TRUE, FALSE))
  expect_json_roundtrip(TRUE)
  expect_json_roundtrip(1)
  expect_json_roundtrip("xyz")
  expect_json_roundtrip(c(1, 2, 3))
  expect_json_roundtrip(c("abc", "xyz"))
})

test_that("integer values keep existing numeric JSON behavior", {
  expect_json_roundtrip(1L, 1)
  expect_json_roundtrip(1:2, as.numeric(1:2))
  expect_json_roundtrip(c(a = 1L), c(a = 1))
})

test_that("lists round trip with current simplification behavior", {
  expect_json_roundtrip(
    list(1L),
    list(1),
    toJSONArgs = list(asIs = FALSE),
    fromJSONArgs = list(simplify = FALSE)
  )
  expect_json_roundtrip(
    list(1, 2),
    list(1, 2),
    toJSONArgs = list(asIs = FALSE),
    fromJSONArgs = list(simplify = FALSE)
  )
  expect_json_roundtrip(
    list(1, 2),
    list(list(1), list(2)),
    toJSONArgs = list(asIs = TRUE),
    fromJSONArgs = list(simplify = FALSE)
  )
  expect_json_roundtrip(
    list(a = 1, b = 2),
    list(a = list(1), b = list(2)),
    toJSONArgs = list(asIs = TRUE),
    fromJSONArgs = list(simplify = FALSE)
  )
})

test_that("nested mixed containers round trip by value", {
  x <- list(
    a = 1,
    b = c(1, 2),
    c = list(1:3, x = c(TRUE, FALSE, FALSE), list(c("a", "b", "c", "d")))
  )

  expect_json_roundtrip(x, compare = all.equal)
})

test_that("empty objects round trip without dropping structure", {
  json <- "[ 1, {}, [1, 3, 5] ]"
  value <- fromJSON(json)
  encoded <- toJSON(value, collapse = " ")

  expect_true(any(duplicated(gsub("[[:space:]]", "", c(json, encoded)))))
})
