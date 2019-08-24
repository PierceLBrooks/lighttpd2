# -*- coding: utf-8 -*-

from base import *
from requests import *
import socketserver
import threading

class HttpBackendHandler(socketserver.StreamRequestHandler):
	def handle(self):
		keepalive = True
		while True:
			reqline = self.rfile.readline().decode('utf-8').rstrip()
			# eprint("Request line: " + repr(reqline))
			reqline = reqline.split(' ', 3)
			if len(reqline) != 3 or reqline[0].upper() != 'GET':
				self.wfile.write(b"HTTP/1.0 400 Bad request\r\n\r\n")
				return
			keepalive_default = True
			if reqline[2].upper() != "HTTP/1.1":
				keepalive = False
				keepalive_default = False
			# read headers; and GET has no body
			while True:
				hdr = self.rfile.readline().decode('utf-8').rstrip()
				if hdr == "": break
				hdr = hdr.split(':', 2)
				if hdr[0].lower() == "connection":
					keepalive = (hdr[1].strip().lower() == "keep-alive")
			# send response
			resp_body = reqline[1].encode('utf-8')
			clen = "Content-Length: {}\r\n".format(len(resp_body)).encode('utf-8')
			ka = b""
			if keepalive != keepalive_default:
				if keepalive:
					ka = b"Connection: keep-alive\r\n"
				else:
					ka = b"Connection: close\r\n"
			resp = b"HTTP/1.1 200 OK\r\n" + ka + clen + b"\r\n" + resp_body
			# eprint("Backend response: " + repr(resp_body))
			self.wfile.write(resp)
			if not keepalive:
				return


class HttpBackend(socketserver.ThreadingMixIn, socketserver.TCPServer):
	allow_reuse_address = True
	def __init__(self):
		self.port = Env.port + 3
		super().__init__(('127.0.0.2', self.port), HttpBackendHandler)

		self.listen_thread = threading.Thread(target = self.serve_forever, name = "HttpBackend-{}".format(self.port))
		self.listen_thread.daemon = True
		self.listen_thread.start()

class TestSimple(CurlRequest):
	URL = "/test.txt"
	EXPECT_RESPONSE_CODE = 200
	EXPECT_RESPONSE_BODY = TEST_TXT
	EXPECT_RESPONSE_HEADERS = [("Content-Type", "text/plain; charset=utf-8")]
	config = """
req_header.overwrite "Host" => "basic-gets";
self_proxy;
"""
	no_docroot = True

# backend gets encoded %2F
class TestProxiedRewrittenEncodedURL(CurlRequest):
	URL = "/foo%2Ffile?abc"
	EXPECT_RESPONSE_BODY = "/dest%2Ffile?abc"
	EXPECT_RESPONSE_CODE = 200
	no_docroot = True
	config = """
rewrite_raw "/foo(.*)" => "/dest$1";
backend_proxy;
"""

# backend gets decoded %2F
class TestProxiedRewrittenDecodedURL(CurlRequest):
	URL = "/foo%2Ffile?abc"
	EXPECT_RESPONSE_BODY = "/dest/file?abc"
	EXPECT_RESPONSE_CODE = 200
	no_docroot = True
	config = """
rewrite "/foo(.*)" => "/dest$1";
backend_proxy;
"""

class Test(GroupTest):
	group = [
		TestSimple,
		TestProxiedRewrittenEncodedURL,
		TestProxiedRewrittenDecodedURL,
	]

	def Prepare(self):
		self.http_backend = HttpBackend()
		self.plain_config = """
setup {{ module_load "mod_proxy"; }}

self_proxy = {{
	proxy "127.0.0.2:{self_port}";
}};
backend_proxy = {{
	proxy "127.0.0.2:{backend_port}";
}};
""".format(
		self_port = Env.port,
		backend_port = self.http_backend.port,
	)

	def Cleanup(self):
		self.http_backend.shutdown()
