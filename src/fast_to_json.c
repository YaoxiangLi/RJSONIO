#include <R.h>
#include <Rinternals.h>
#include <R_ext/Boolean.h>
#include <R_ext/Rdynload.h>
#include <limits.h>
#include <stdio.h>
#include <string.h>

typedef struct {
    char *data;
    R_xlen_t len;
    R_xlen_t cap;
} json_buffer;

static void buffer_init(json_buffer *buf, R_xlen_t cap)
{
    if (cap < 128)
        cap = 128;
    buf->data = (char *) R_alloc((size_t) cap, sizeof(char));
    buf->len = 0;
    buf->cap = cap;
    buf->data[0] = '\0';
}

static void buffer_reserve(json_buffer *buf, R_xlen_t extra)
{
    R_xlen_t needed = buf->len + extra + 1;
    char *next;

    if (needed <= buf->cap)
        return;

    R_xlen_t cap = buf->cap;
    while (cap < needed)
        cap *= 2;

    next = (char *) R_alloc((size_t) cap, sizeof(char));
    memcpy(next, buf->data, (size_t) buf->len);
    next[buf->len] = '\0';
    buf->data = next;
    buf->cap = cap;
}

static void buffer_append_n(json_buffer *buf, const char *value, R_xlen_t n)
{
    buffer_reserve(buf, n);
    memcpy(buf->data + buf->len, value, (size_t) n);
    buf->len += n;
    buf->data[buf->len] = '\0';
}

static void buffer_append(json_buffer *buf, const char *value)
{
    buffer_append_n(buf, value, (R_xlen_t) strlen(value));
}

static int is_supported_type(SEXP x)
{
    return TYPEOF(x) == INTSXP || TYPEOF(x) == LGLSXP || TYPEOF(x) == STRSXP;
}

static int scalar_logical(SEXP x)
{
    return LOGICAL(x)[0] == TRUE;
}

static const char *scalar_string(SEXP x)
{
    return CHAR(STRING_ELT(x, 0));
}

static SEXP make_scalar_string(const char *value)
{
    SEXP ans = PROTECT(allocVector(STRSXP, 1));
    SET_STRING_ELT(ans, 0, mkChar(value));
    UNPROTECT(1);
    return ans;
}

static void append_quoted_name(json_buffer *buf, SEXP names, R_xlen_t i)
{
    const char *name = CHAR(STRING_ELT(names, i));
    buffer_append(buf, "\"");
    buffer_append(buf, name);
    buffer_append(buf, "\"");
}

static void append_character_value(json_buffer *buf, SEXP x, R_xlen_t i, const char *na_value)
{
    SEXP elt = STRING_ELT(x, i);
    if (elt == NA_STRING) {
        buffer_append(buf, na_value);
        return;
    }

    const char *value = CHAR(elt);
    buffer_append(buf, "\"");
    for (const unsigned char *p = (const unsigned char *) value; *p; p++) {
        switch (*p) {
        case '\\':
            buffer_append(buf, "\\\\");
            break;
        case '\t':
            buffer_append(buf, "\\t");
            break;
        case '\n':
            buffer_append(buf, "\\n");
            break;
        case '\b':
            buffer_append(buf, "\\b");
            break;
        case '\r':
            buffer_append(buf, "\\r");
            break;
        case '\f':
            buffer_append(buf, "\\f");
            break;
        case '"':
            buffer_append(buf, "\\\"");
            break;
        default:
            buffer_append_n(buf, (const char *) p, 1);
        }
    }
    buffer_append(buf, "\"");
}

static void append_integer_value(json_buffer *buf, SEXP x, R_xlen_t i, const char *na_value)
{
    char tmp[64];
    int value = INTEGER(x)[i];

    if (value == NA_INTEGER) {
        buffer_append(buf, na_value);
        return;
    }

    snprintf(tmp, sizeof(tmp), "%d", value);
    buffer_append(buf, tmp);
}

static void append_logical_value(json_buffer *buf, SEXP x, R_xlen_t i, const char *na_value)
{
    int value = LOGICAL(x)[i];

    if (value == NA_LOGICAL) {
        buffer_append(buf, na_value);
        return;
    }

    buffer_append(buf, value ? "true" : "false");
}

static void append_value(json_buffer *buf, SEXP x, R_xlen_t i, const char *na_value)
{
    switch (TYPEOF(x)) {
    case INTSXP:
        append_integer_value(buf, x, i, na_value);
        break;
    case LGLSXP:
        append_logical_value(buf, x, i, na_value);
        break;
    case STRSXP:
        append_character_value(buf, x, i, na_value);
        break;
    }
}

SEXP R_toJSONAtomicFast(SEXP x, SEXP container, SEXP with_names, SEXP collapse,
                        SEXP na_value, SEXP escape_escapes)
{
    R_xlen_t n = XLENGTH(x);
    int use_container = scalar_logical(container);
    int use_names = scalar_logical(with_names);
    int escape = scalar_logical(escape_escapes);
    const char *collapse_value;
    const char *na_string;
    SEXP names;
    json_buffer buf;

    if (!is_supported_type(x) || !escape || TYPEOF(collapse) != STRSXP ||
        TYPEOF(na_value) != STRSXP || XLENGTH(collapse) != 1 || XLENGTH(na_value) != 1)
        return R_NilValue;

    if (!use_container && n != 1) {
        if (TYPEOF(x) == STRSXP && n == 0)
            return make_scalar_string("[ ]");
        return R_NilValue;
    }

    names = getAttrib(x, R_NamesSymbol);
    if (use_names && (names == R_NilValue || XLENGTH(names) != n))
        return R_NilValue;

    collapse_value = scalar_string(collapse);
    na_string = scalar_string(na_value);

    buffer_init(&buf, n * 16 + 32);

    if (!use_container) {
        append_value(&buf, x, 0, na_string);
        return make_scalar_string(buf.data);
    }

    if (use_names) {
        buffer_append(&buf, "{");
        buffer_append(&buf, collapse_value);
        for (R_xlen_t i = 0; i < n; i++) {
            if (i > 0) {
                buffer_append(&buf, ",");
                buffer_append(&buf, collapse_value);
            }
            append_quoted_name(&buf, names, i);
            buffer_append(&buf, ": ");
            append_value(&buf, x, i, na_string);
        }
        buffer_append(&buf, collapse_value);
        buffer_append(&buf, "}");
    } else {
        buffer_append(&buf, "[ ");
        for (R_xlen_t i = 0; i < n; i++) {
            if (i > 0)
                buffer_append(&buf, ", ");
            append_value(&buf, x, i, na_string);
        }
        buffer_append(&buf, " ]");
    }

    return make_scalar_string(buf.data);
}
