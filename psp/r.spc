create or replace package r is

	ct_http   constant pls_integer := 0;
	ct_nodejs constant pls_integer := 1;

	na pv.vc_arr;
	va pv.vc_arr;

	procedure set_prog(x$prog varchar2 := null);

	procedure getblob
	(
		p_len  in pls_integer,
		p_blob in out nocopy blob
	);

	procedure body2clob;
	procedure body2nclob;
	procedure body2auto;

	procedure read_line_init(nl varchar2 := null);
	procedure read_line(line in out nocopy varchar2);
	procedure read_nline(line in out nocopy nvarchar2);
	function read_line_no_more return boolean;

	function call_type return varchar2;
	function is_xhr return boolean;
	function not_xhr return boolean;
	function method return varchar2;
	function protocol(use_proxy boolean := true) return varchar2;
	function protov return varchar2;
	function sdns(base_cnt pls_integer := 2) return varchar2;
	function pdns(base_cnt pls_integer := 2) return varchar2;
	function hostname return varchar2;
	function port return pls_integer;
	function host return varchar2;

	function prog return varchar2;
	function pack return varchar2;
	function proc return varchar2;
	function type return varchar2;
	function is_readonly return boolean;
	function is_readwrite return boolean;

	function gid return varchar2;
	function uid return varchar2;
	function site(use_proxy boolean := true) return varchar2;
	function url return varchar2;
	function dir return varchar2;
	function pathname return varchar2;
	function path return varchar2;
	function subpath return varchar2;
	function search return varchar2;
	function qstr return varchar2;
	function url_full return varchar2;
	function dir_full return varchar2;

	procedure req_charset(cs varchar2);
	procedure req_charset_db;
	procedure req_charset_ndb;
	procedure req_charset_utf8;

	function is_lack(name varchar2) return boolean;
	function is_null(name varchar2) return boolean;
	function not_lack(name varchar2) return boolean;
	function not_null(name varchar2) return boolean;
	function get
	(
		name   varchar2,
		defval varchar2 := null
	) return varchar2;
	procedure set
	(
		name  varchar2,
		value varchar2
	);
	procedure sets
	(
		name varchar2,
		vals st
	);
	procedure sets_init(name varchar2);
	procedure sets_add
	(
		name  varchar2,
		value varchar2
	);
	procedure del(name varchar2);
	procedure del(names st);

	procedure setc
	(
		name  varchar2,
		value varchar2 character set any_cs
	);

	procedure setn
	(
		name  varchar2,
		value number
	);

	procedure setd
	(
		name  varchar2,
		value date
	);

	procedure setb
	(
		name  varchar2,
		value boolean := true
	);

	function getc
	(
		name   varchar2,
		defval varchar2 := null,
		idx    pls_integer := 1
	) return varchar2;

	function getnc
	(
		name   varchar2,
		defval nvarchar2 := null,
		idx    pls_integer := 1
	) return nvarchar2;

	function getn
	(
		name   varchar2,
		defval number := null,
		format varchar2 := null,
		idx    pls_integer := 1
	) return number;

	function getd
	(
		name   varchar2,
		defval date := null,
		format varchar2 := null,
		idx    pls_integer := 1
	) return date;

	function getb
	(
		name   varchar2,
		defval boolean := null,
		idx    pls_integer := 1
	) return boolean;

	procedure gets
	(
		name  varchar2,
		value in out nocopy st
	);
	function cnt(name varchar2) return pls_integer;
	function gets(name varchar2) return st;
	function dump
	(
		name    varchar2,
		restore boolean := false
	) return varchar2;
	function unescape(value varchar2) return varchar2;
	function vqstr return varchar2;
	function vqstr(names varchar2) return varchar2;
	function idle return number;
	function lat return date;
	function return_before_set_this(name varchar2) return varchar2;

	function header(name varchar2) return varchar2;
	function negotiation
	(
		header   varchar2,
		supports varchar2
	) return varchar2;

	function user return varchar2;
	function pass return varchar2;

	function cookie(name varchar2) return varchar2;

	function msid return varchar2;
	function bsid return varchar2;

	function dbu return varchar2;
	function file return varchar2;

	function etag return varchar2;
	function lmt return date;
	function referer return varchar2;
	function referer2 return varchar2;
	function ua return varchar2;

	function client_addr(use_proxy boolean := true) return varchar2;
	function client_port(use_proxy boolean := true) return pls_integer;
	function server_family return varchar2;
	function server_addr return varchar2;
	function server_port return pls_integer;

	function cid return varchar2;
	function cfg return varchar2;
	function slot return varchar2;
	function cslot return pls_integer;

	function db_env(n varchar2) return varchar2;
	function instance return pls_integer;
	function database_role return varchar2;
	function db_unique_name return varchar2;

	function c
	(
		name   varchar2,
		defval varchar2 := null,
		idx    pls_integer := 1
	) return varchar2;

	function n
	(
		name   varchar2,
		defval number := null,
		format varchar2 := null,
		idx    pls_integer := 1
	) return number;

	function d
	(
		name   varchar2,
		defval date := null,
		format varchar2 := null,
		idx    pls_integer := 1
	) return date;

	function b
	(
		name   varchar2,
		defval boolean := null,
		idx    pls_integer := 1
	) return boolean;

	procedure set
	(
		name  varchar2,
		value varchar2 character set any_cs
	);

	procedure set
	(
		name  varchar2,
		value number
	);

	procedure set
	(
		name  varchar2,
		value date
	);

	procedure set
	(
		name  varchar2,
		value boolean := true
	);

end r;
/
