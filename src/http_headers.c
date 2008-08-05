
#include "http_headers.h"

static void _string_free(gpointer p) {
	g_string_free((GString*) p, TRUE);
}

http_headers* http_headers_new() {
	http_headers* headers = g_slice_new0(http_headers);
	headers->table = g_hash_table_new_full(
		(GHashFunc) g_string_hash, (GEqualFunc) g_string_equal,
		_string_free, _string_free);
	return headers;
}

void http_headers_reset(http_headers* headers) {
	g_hash_table_remove_all(headers->table);
}

void http_headers_free(http_headers* headers) {
	if (!headers) return;
	g_hash_table_destroy(headers->table);
	g_slice_free(http_headers, headers);
}

/* Just insert the header (using lokey)
 */
static void header_insert(http_headers *headers, GString *lokey, GString *key, GString *value) {
	GString *newval = g_string_sized_new(key->len + value->len + 2);

	g_string_append_len(newval, key->str, key->len);
	g_string_append_len(newval, ": ", 2);
	g_string_append_len(newval, value->str, value->len);

	g_hash_table_insert(headers->table, lokey, newval);
}

/** If header does not exist, just insert normal header. If it exists, append (", %s", value) */
void http_header_append(http_headers *headers, GString *key, GString *value) {
	GString *lokey, *tval;

	lokey = g_string_new_len(key->str, key->len);
	g_string_ascii_down(lokey);
	tval = (GString*) g_hash_table_lookup(headers->table, lokey);
	if (!tval) {
		header_insert(headers, lokey, key, value);
	} else {
		g_string_free(lokey, TRUE);
		g_string_append_len(tval, ", ", 2);
		g_string_append_len(tval, value->str, value->len);
	}
}

/** If header does not exist, just insert normal header. If it exists, append ("\r\n%s: %s", key, value) */
void http_header_insert(http_headers *headers, GString *key, GString *value) {
	GString *lokey, *tval;

	lokey = g_string_new_len(key->str, key->len);
	g_string_ascii_down(lokey);
	tval = (GString*) g_hash_table_lookup(headers->table, lokey);
	if (!tval) {
		header_insert(headers, lokey, key, value);
	} else {
		g_string_free(lokey, TRUE);
		g_string_append_len(tval, "\r\n", 2);
		g_string_append_len(tval, key->str, key->len);
		g_string_append_len(tval, ": ", 2);
		g_string_append_len(tval, value->str, value->len);
	}
}

/** If header does not exist, just insert normal header. If it exists, overwrite the value */
void http_header_overwrite(http_headers *headers, GString *key, GString *value) {
	GString *lokey, *tval;

	lokey = g_string_new_len(key->str, key->len);
	g_string_ascii_down(lokey);
	tval = (GString*) g_hash_table_lookup(headers->table, lokey);
	if (!tval) {
		header_insert(headers, lokey, key, value);
	} else {
		g_string_free(lokey, TRUE);
		g_string_truncate(tval, 0);
		g_string_append_len(tval, key->str, key->len);
		g_string_append_len(tval, ": ", 2);
		g_string_append_len(tval, value->str, value->len);
	}
}

LI_API gboolean http_header_remove(http_headers *headers, GString *key) {
	GString *lokey;
	gboolean res;

	lokey = g_string_new_len(key->str, key->len);
	g_string_ascii_down(lokey);
	res = g_hash_table_remove(headers->table, lokey);
	g_string_free(lokey, TRUE);
	return res;
}