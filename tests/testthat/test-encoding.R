x <- "Open Bar $300 \u5564\u9152\u3001\u6C23\u9152 \u4EFB\u98F2"

test_that("UTF-8 content embedded in JSON is parsed", {
  parsed <- fromJSON(paste('{"tweet":"', x, '"}', sep = ""))

  expect_equal(unname(parsed[["tweet"]]), x)
  expect_true(isValidJSON(I(toJSON(parsed))))
})

test_that("unsupported encodings are rejected", {
  expect_error(fromJSON("[1]", encoding = "not-an-encoding"), "unrecognized encoding")
})
