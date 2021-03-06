create or replace package body output is

	-- private
	procedure chunk_init is
	begin
		pv.pg_buf   := '';
		pv.ph_buf   := '';
		pv.pg_index := 0;
		pv.pg_len   := 0;
		pv.pg_parts.delete;
		pv.ph_parts.delete;
	end;

	procedure "_init"(passport pls_integer) is
	begin
		if passport != 80526 then
			raise_application_error(-20000, 'can not call psp.web''s internal method');
		end if;
		chunk_init;
		pv.pg_css   := '';
		pv.pg_cssno := null;
		pv.flushed  := false;
		sts.stack   := '';
	end;

	-- private
	function get_buf_byte_len return pls_integer is
	begin
		if pv.pg_nchar then
			return pv.pg_len + nvl(lengthb(pv.pg_buf), 0) + nvl(lengthb(pv.bom) / 2, 0);
		else
			return pv.pg_len + nvl(lengthb(pv.ph_buf), 0) + nvl(lengthb(pv.bom) / 2, 0);
		end if;
	end;

	procedure write_head is
		v1 number(10);
		v2 number(10);
	begin
		if pv.header_writen then
			return;
		end if;
		pv.header_writen := true;
		if pv.bom is not null then
			pv.headers('x-pw-bom-hex') := pv.bom;
		end if;
		k_debug.time_header('before-resp');
		if pv.status_code = 200 and r.type = 'c' and r.getc('f$feedback', 'Y') = 'Y' then
			pv.headers('x-pw-feedback') := 'Y';
		end if;
		bios.write_head;
	end;

	procedure switch_css is
	begin
		if pv.use_stream = false then
			raise_application_error(-20000, 'force no stream found when switch_css');
		end if;
		flush;
		-- write embed_frame for insertion point
		bios.wpi(pv.cslot_id * 256 * 256 + 4 * 256 + 0);
		bios.wpi(0);
	end;

	procedure css(str varchar2 character set any_cs) is
	begin
		pv.pg_css := pv.pg_css || str;
	end;

	-- private, called by .flush or .finish
	procedure write_buf(p_len pls_integer) is
		v_plen pls_integer := 0;
	begin
		if p_len = 0 then
			return;
		end if;
		if pv.entry is not null then
			if pv.disproto = 'FCGI' then
				v_plen := 8 - mod(p_len, 8);
				if v_plen = 8 then
					v_plen := 0;
				else
					line(rpad(' ', v_plen, ' '), null, 0);
				end if;
			end if;
			bios.write_frame(1, p_len + v_plen, v_plen);
		end if;
	
		if pv.entry is null then
			if pv.pg_nchar then
				for i in 1 .. pv.pg_index loop
					k_debug.print_to_ide(pv.pg_parts(i));
				end loop;
				k_debug.print_to_ide(pv.pg_buf);
			else
				for i in 1 .. pv.pg_index loop
					k_debug.print_to_ide(pv.ph_parts(i));
				end loop;
				k_debug.print_to_ide(pv.ph_buf);
			end if;
		else
			if pv.pg_nchar then
				for i in 1 .. pv.pg_index loop
					pv.wlen := utl_tcp.write_text(pv.c, pv.pg_parts(i));
				end loop;
				pv.wlen := utl_tcp.write_text(pv.c, pv.pg_buf);
			else
				for i in 1 .. pv.pg_index loop
					pv.wlen := utl_tcp.write_text(pv.c, pv.ph_parts(i));
				end loop;
				pv.wlen := utl_tcp.write_text(pv.c, pv.ph_buf);
			end if;
		end if;
		chunk_init;
	end;

	procedure flush is
	begin
		if not pv.use_stream then
			return;
		end if;
		if pv.flushed = false then
			pv.flushed := true;
			pv.use_stream := true;
			pv.headers('Transfer-Encoding') := 'chunked';
		end if;
		if not pv.header_writen then
			write_head;
		end if;
		if pv.pg_conv then
			pv.pg_buf := convert(pv.pg_buf, pv.charset_ora, pv.cs_nchar);
		end if;
		write_buf(get_buf_byte_len);
	end;

	procedure do_css_write is
		v     varchar2(4000);
		nl    varchar2(2) := chr(13) || chr(10);
		v_md5 raw(16);
	begin
		if pv.pg_css is null then
			pv.pg_css := ' ';
		end if;
		if pv.charset_ora != pv.cs_nchar then
			pv.pg_css := convert(pv.pg_css, pv.charset_ora, pv.cs_nchar);
		end if;
		if pv.headers('x-embed-css') = 'link' then
			v_md5 := dbms_crypto.hash(utl_raw.cast_to_raw(pv.pg_css), dbms_crypto.hash_md5);
			bios.wpi(pv.cslot_id * 256 * 256 + 5 * 256 + 0);
			bios.wpi(16);
			pv.wlen := utl_tcp.write_raw(pv.c, v_md5);
		end if;
		bios.wpi(pv.cslot_id * 256 * 256 + 3 * 256 + 0);
		bios.wpi(lengthb(pv.pg_css));
		pv.wlen := utl_tcp.write_text(pv.c, pv.pg_css);
	end;

	procedure switch is
	begin
		pv.pg_index := pv.pg_index + 1;
		if pv.pg_nchar then
			if pv.pg_conv then
				pv.pg_parts(pv.pg_index) := convert(pv.pg_buf, pv.charset_ora, pv.cs_nchar);
			else
				pv.pg_parts(pv.pg_index) := pv.pg_buf;
			end if;
			pv.pg_len := pv.pg_len + lengthb(pv.pg_parts(pv.pg_index));
		else
			pv.ph_parts(pv.pg_index) := pv.ph_buf;
			pv.pg_len := pv.pg_len + lengthb(pv.ph_buf);
		end if;
	end;

	procedure line
	(
		str    varchar2 character set any_cs,
		nl     varchar2 := chr(10),
		indent pls_integer := null
	) is
	begin
		if pv.pg_nchar then
			pv.pg_buf := pv.pg_buf || (lpad(n' ', indent, ' ') || str || nl);
		else
			pv.ph_buf := pv.ph_buf || (lpad(' ', indent, ' ') || str || nl);
		end if;
	exception
		when others then
			-- 6502 numeric or value error: character string buffer too small
			if pv.use_stream then
				flush;
			else
				switch;
			end if;
			if pv.pg_nchar then
				pv.pg_buf := lpad(' ', indent, ' ') || str || nl;
			else
				pv.ph_buf := lpad(' ', indent, ' ') || str || nl;
			end if;
	end;

	-- Refactored procedure compute_hash 
	function compute_hash return varchar2 is
		v_raw   raw(32767);
		v_nclob nclob;
		v_clob  clob;
	begin
		if pv.pg_nchar then
			dbms_lob.createtemporary(v_nclob, true, dur => dbms_lob.call);
			for i in 1 .. pv.pg_index loop
				dbms_lob.writeappend(v_nclob, length(pv.pg_parts(i)), pv.pg_parts(i));
			end loop;
			dbms_lob.writeappend(v_nclob, length(pv.pg_buf), pv.pg_buf);
			v_raw := dbms_crypto.hash(v_nclob, dbms_crypto.hash_md5);
		else
			dbms_lob.createtemporary(v_clob, true, dur => dbms_lob.call);
			for i in 1 .. pv.pg_index loop
				dbms_lob.writeappend(v_clob, length(pv.ph_parts(i)), pv.ph_parts(i));
			end loop;
			dbms_lob.writeappend(v_clob, length(pv.ph_buf), pv.ph_buf);
			v_raw := dbms_crypto.hash(v_clob, dbms_crypto.hash_md5);
		end if;
		return utl_raw.cast_to_varchar2(utl_encode.base64_encode(v_raw));
	end compute_hash;

	procedure finish is
		v_len integer;
		v_md5 varchar2(32);
		v_tmp nvarchar2(32767);
	begin
		-- if use stream, flush the final buffered content and the end marker out
		if pv.flushed then
			flush;
			if pv.headers.exists('x-embed-css') then
				do_css_write;
			end if;
			return;
		end if;
	
		if pv.pg_conv then
			pv.pg_buf := convert(pv.pg_buf, pv.charset_ora, pv.cs_nchar);
		end if;
		v_len := get_buf_byte_len;
	
		if v_len = 0 then
			goto print_http_headers;
		end if;
	
		if pv.etag_md5 and pv.status_code = 200 then
			v_md5 := compute_hash;
			h.etag(v_md5);
			if r.etag = '"' || v_md5 || '"' then
				h.status_line(304);
				v_len := 0;
			end if;
		end if;
	
		<<print_http_headers>>
		pv.headers('Content-Length') := to_char(v_len);
		if v_len = 0 then
			pv.headers.delete('Content-Type');
			pv.headers.delete('Content-Encoding');
		end if;
		write_head;
		write_buf(v_len);
	end;

end output;
/
