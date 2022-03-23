CREATE OR REPLACE FUNCTION COLUMN_NAMES
  ( p_query IN CLOB,
    p_format CLOB,
    p_separator IN VARCHAR2 DEFAULT CHR(13)||CHR(10) 
  ) RETURN CLOB
IS
  p_query_out         CLOB;              -- ���������� ��� ��������������� p_query  (�.�. ��� ������ ���� � ������ IN)
  p_format_out        CLOB;              -- ���������� ��� ��������������� p_format (�.�. ��� ������ ���� � ������ IN)
  tag_2_qty           NUMBER;            -- ���-�� ����� �� ������ ��������� p_format 
  cur_fh              PLS_INTEGER;       -- ������������� �������
  col_qty_fh          PLS_INTEGER;       -- ���� ��������� ���-�� �������� �������
  col_names_coll_fh   DBMS_SQL.DESC_TAB; -- ��������� � ������� ��������
  p_query_answer      CLOB;              -- �����, ������� ���������� �������  
BEGIN
  -- ������� �� ��������� ������� �������
  p_query_out  := REPLACE(p_query, q'['']', q'[']');
  p_format_out := REPLACE(p_format, q'['']', q'[']');
    DBMS_OUTPUT.PUT_LINE(N'����� ������� �� ������� ������� (���� ���� �� �� ����) p_query_out = ' || p_query_out);
    DBMS_OUTPUT.PUT_LINE(N'����� ������� �� ������� ������� (���� ���� �� �� ����) p_format_out = ' || p_format_out);
    DBMS_OUTPUT.PUT_LINE('= = = = = = = = = ='); 
  -- ���������� ��� ��������
  cur_fh := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(cur_fh, p_query_out, DBMS_SQL.NATIVE);
  DBMS_SQL.DESCRIBE_COLUMNS (cur_fh, col_qty_fh, col_names_coll_fh);
  -- ��������� ������� ��������� p_format
  tag_2_qty := REGEXP_COUNT(p_format_out, '<#[^#]*#>');
  -- ��������� �������� ������-������
  FOR i IN 1..col_names_coll_fh.LAST 
  LOOP
    IF tag_2_qty > 0
      THEN
        FOR x IN 1..tag_2_qty LOOP
          IF LOWER(REGEXP_REPLACE(REGEXP_SUBSTR(p_format, '<#[^#]+#>', 1, x), '<#([^#]+)#>', '\1') ) = 'fh_column'				-- fh_column ��� ��� �������
            THEN p_format_out := REGEXP_REPLACE(p_format_out, '([^<]*)<#' || 'fh_column' || '#>(.*)', 
                                                '\1' || col_names_coll_fh(i).col_name || '\2', 1, 1, 'i');
              DBMS_OUTPUT.PUT_LINE(N'�� ' || i || N'-� ������� (i) ���� � ' || x || N' (x) ���� ������ fh_column � p_format_out = ' || p_format_out);
          ELSIF LOWER(REGEXP_REPLACE(REGEXP_SUBSTR(p_format, '<#[^#]+#>', 1, x), '<#([^#]+)#>', '\1') ) = 'fh_column_number'	-- fh_column_number ��� ���������� ����� ������� � �������
            THEN p_format_out := REGEXP_REPLACE(p_format_out, '([^<]*)<#' || 'fh_column_number' || '#>(.*)', 
                                                '\1' || i || '\2', 1, 1, 'i');
              DBMS_OUTPUT.PUT_LINE(N'�� ' || i || N'-� ������� (i) ���� � ' || x || N' (x) ���� ������ fh_column_number � p_format_out = ' || p_format_out);
          ELSIF LOWER(REGEXP_REPLACE(REGEXP_SUBSTR(p_format, '<#[^#]+#>', 1, x), '<#([^#]+)#>', '\1') ) = 'fh_column_count'		-- fh_column_count ��� ����� ���-�� �������� � �������
            THEN p_format_out := REGEXP_REPLACE(p_format_out, '([^<]*)<#' || 'fh_column_count' || '#>(.*)', 
                                                '\1' || col_names_coll_fh.LAST || '\2', 1, 1, 'i');
              DBMS_OUTPUT.PUT_LINE(N'�� ' || i || N'-� ������� (i) ���� � ' || x || N' (x) ���� ������ fh_column_count � p_format_out = ' || p_format_out);
          ELSE NULL;
          END IF;
        END LOOP;
      p_query_answer := p_query_answer || p_format_out || p_separator;
      p_format_out := REPLACE(p_format, q'['']', q'[']');
      ELSE NULL;
    END IF;
  END LOOP;
  p_query_answer := RTRIM(p_query_answer, p_separator);
    /*DBMS_OUTPUT.PUT_LINE(N'��������� ������� COLUMN_NAMES: ' || p_query_answer);*/
  RETURN p_query_answer;
EXCEPTION
  WHEN OTHERS  -- � ������ ���� ������ ����� �������� ��� ������
    THEN DBMS_OUTPUT.PUT_LINE(N'������� COLUMN_NAMES �� ������� �������� ��-�� ������ �� ������� ����������');
END;
/


-- ������� �������������

SELECT COLUMN_NAMES('select * from nc_sneakers', '<#fh_column#>', ', ') AS func_res FROM dual; -- ����� �������� ���� �������� ����� ������� �� ������� nc_sneakers

SELECT COLUMN_NAMES('select * from nc_sneakers', '<#fh_column#> ��� <#fh_column_number#>-� ������� �� <#fh_column_count#>') 
AS func_res FROM dual;			-- ����� �������� ���� �������� �� ������� nc_sneakers � ����: "SN_ID ��� 1-� ������� �� 8" � �.�. 