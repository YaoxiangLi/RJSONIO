test_that("atomic fast path matches existing integer JSON output", {
  expect_identical(toJSONAtomicFast(1:3, TRUE, FALSE, "\n  ", "null", TRUE), "[ 1, 2, 3 ]")
  expect_identical(
    toJSONAtomicFast(c(a = 1L, b = NA_integer_), TRUE, TRUE, "\n  ", "null", TRUE),
    toJSON(c(a = 1L, b = NA_integer_))
  )
  expect_identical(toJSONAtomicFast(1L, FALSE, FALSE, "\n  ", "null", TRUE), "1")
})

test_that("atomic fast path matches existing logical JSON output", {
  value <- c(TRUE, FALSE, NA)
  expect_identical(toJSONAtomicFast(value, TRUE, FALSE, "\n", "null", TRUE), "[ true, false, null ]")
  expect_identical(toJSONAtomicFast(TRUE, FALSE, FALSE, "\n", "null", TRUE), "true")
  expect_identical(
    toJSONAtomicFast(c(a = TRUE, b = NA), TRUE, TRUE, "\n", "null", TRUE),
    "{\n\"a\": true,\n\"b\": null\n}"
  )
})

test_that("atomic fast path matches existing character JSON output", {
  value <- c("a", "x\n", "tab\t", "quote\"", "slash\\", NA_character_)
  expect_identical(
    toJSONAtomicFast(value, TRUE, FALSE, "\n", "null", TRUE),
    "[ \"a\", \"x\\n\", \"tab\\t\", \"quote\\\"\", \"slash\\\\\", null ]"
  )
  expect_identical(
    toJSONAtomicFast(c("\b", "\r", "\f"), TRUE, FALSE, "\n", "null", TRUE),
    "[ \"\\b\", \"\\r\", \"\\f\" ]"
  )

  named <- c(a = "x\n", b = NA_character_)
  expect_identical(
    toJSONAtomicFast(named, TRUE, TRUE, "\n", "null", TRUE),
    "{\n\"a\": \"x\\n\",\n\"b\": null\n}"
  )
  expect_identical(toJSONAtomicFast(character(), FALSE, FALSE, "\n", "null", TRUE), "[ ]")
})

test_that("atomic fast path handles strings larger than the initial buffer", {
  value <- paste(rep("abcdef", 100), collapse = "")
  expect_identical(toJSONAtomicFast(value, TRUE, FALSE, "\n", "null", TRUE), toJSON(value))
})

test_that("toJSON uses the fast path without changing supported atomic output", {
  expect_identical(toJSON(1:3), "[ 1, 2, 3 ]")
  expect_identical(toJSON(c(TRUE, FALSE, NA)), "[ true, false, null ]")
  expect_identical(toJSON(c("a", "b", NA_character_)), "[ \"a\", \"b\", null ]")
  expect_true(isValidJSON(I(toJSON(data.frame(a = 1:2, b = c("x", "y"))))))
})

test_that("atomic fast path declines unsupported cases", {
  expect_null(toJSONAtomicFast(c(1.1, 2.2), TRUE, FALSE, "\n", "null", TRUE))
  expect_null(toJSONAtomicFast(list(a = 1), TRUE, TRUE, "\n", "null", TRUE))
  expect_null(toJSONAtomicFast(1:2, TRUE, TRUE, "\n", "null", TRUE))
  expect_null(toJSONAtomicFast(c("a\nb"), TRUE, FALSE, "\n", "NA", FALSE))
})
