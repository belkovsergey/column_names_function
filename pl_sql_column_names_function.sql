CREATE OR REPLACE FUNCTION COLUMN_NAMES
  ( p_query IN CLOB,
    p_format CLOB,
    p_separator IN VARCHAR2 DEFAULT CHR(13)||CHR(10) 
  ) RETURN CLOB
IS
  p_query_out         CLOB;              -- ïåðåìåííàÿ äëÿ ìîäèôèöèðîâàíèÿ p_query  (ò.ê. îíà äîëæíà áûòü â ðåæèìå IN)
  p_format_out        CLOB;              -- ïåðåìåííàÿ äëÿ ìîäèôèöèðîâàíèÿ p_format (ò.ê. îíà äîëæíà áûòü â ðåæèìå IN)
  tag_2_qty           NUMBER;            -- êîë-âî òåãîâ âî âòîðîì ïàðàìåòðå p_format 
  cur_fh              PLS_INTEGER;       -- èäåíòèôèêàòîð êóðñîðà
  col_qty_fh          PLS_INTEGER;       -- ñþäà çàïèøåòñÿ êîë-âî ñòîëáöîâ çàïðîñà
  col_names_coll_fh   DBMS_SQL.DESC_TAB; -- êîëëåêöèÿ ñ èìåíàìè ñòîëáöîâ
  p_query_answer      CLOB;              -- îòâåò, êîòîðûé âîçâðàùàåò ôóíêöèÿ  
BEGIN
  -- î÷èñòêà îò âîçìîæíûõ äâîéíûõ êàâû÷åê
  p_query_out  := REPLACE(p_query, q'['']', q'[']');
  p_format_out := REPLACE(p_format, q'['']', q'[']');
    DBMS_OUTPUT.PUT_LINE(N'Ïîñëå î÷èñòêè îò äâîéíûõ êàâû÷åê (äàæå åñëè èõ íå áûëî) p_query_out = ' || p_query_out);
    DBMS_OUTPUT.PUT_LINE(N'Ïîñëå î÷èñòêè îò äâîéíûõ êàâû÷åê (äàæå åñëè èõ íå áûëî) p_format_out = ' || p_format_out);
    DBMS_OUTPUT.PUT_LINE('= = = = = = = = = ='); 
  -- èçâëå÷åíèå èì¸í ñòîëáöîâ
  cur_fh := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(cur_fh, p_query_out, DBMS_SQL.NATIVE);
  DBMS_SQL.DESCRIBE_COLUMNS (cur_fh, col_qty_fh, col_names_coll_fh);
  -- îáðàáîòêà âòîðîãî ïàðàìåòðà p_format
  tag_2_qty := REGEXP_COUNT(p_format_out, '<#[^#]*#>');
  -- ïîëó÷åíèå èòîãîâîé ñòðîêè-îòâåòà
  FOR i IN 1..col_names_coll_fh.LAST 
  LOOP
    IF tag_2_qty > 0
      THEN
        FOR x IN 1..tag_2_qty LOOP
          IF LOWER(REGEXP_REPLACE(REGEXP_SUBSTR(p_format, '<#[^#]+#>', 1, x), '<#([^#]+)#>', '\1') ) = 'fh_column'				-- fh_column ýòî èìÿ ñòîëáöà
            THEN p_format_out := REGEXP_REPLACE(p_format_out, '([^<]*)<#' || 'fh_column' || '#>(.*)', 
                                                '\1' || col_names_coll_fh(i).col_name || '\2', 1, 1, 'i');
              DBMS_OUTPUT.PUT_LINE(N'Íà ' || i || N'-ì ïðîõîäå (i) øàãà ¹ ' || x || N' (x) áûëà çàìåíà fh_column è p_format_out = ' || p_format_out);
          ELSIF LOWER(REGEXP_REPLACE(REGEXP_SUBSTR(p_format, '<#[^#]+#>', 1, x), '<#([^#]+)#>', '\1') ) = 'fh_column_number'	-- fh_column_number ýòî ïîðÿäêîâûé íîìåð ñòîëáöà â çàïðîñå
            THEN p_format_out := REGEXP_REPLACE(p_format_out, '([^<]*)<#' || 'fh_column_number' || '#>(.*)', 
                                                '\1' || i || '\2', 1, 1, 'i');
              DBMS_OUTPUT.PUT_LINE(N'Íà ' || i || N'-ì ïðîõîäå (i) øàãà ¹ ' || x || N' (x) áûëà çàìåíà fh_column_number è p_format_out = ' || p_format_out);
          ELSIF LOWER(REGEXP_REPLACE(REGEXP_SUBSTR(p_format, '<#[^#]+#>', 1, x), '<#([^#]+)#>', '\1') ) = 'fh_column_count'		-- fh_column_count ýòî îáùåå êîë-âî ñòîëáöîâ â çàïðîñå
            THEN p_format_out := REGEXP_REPLACE(p_format_out, '([^<]*)<#' || 'fh_column_count' || '#>(.*)', 
                                                '\1' || col_names_coll_fh.LAST || '\2', 1, 1, 'i');
              DBMS_OUTPUT.PUT_LINE(N'Íà ' || i || N'-ì ïðîõîäå (i) øàãà ¹ ' || x || N' (x) áûëà çàìåíà fh_column_count è p_format_out = ' || p_format_out);
          ELSE NULL;
          END IF;
        END LOOP;
      p_query_answer := p_query_answer || p_format_out || p_separator;
      p_format_out := REPLACE(p_format, q'['']', q'[']');
      ELSE NULL;
    END IF;
  END LOOP;
  p_query_answer := RTRIM(p_query_answer, p_separator);
    /*DBMS_OUTPUT.PUT_LINE(N'Ðåçóëüòàò ôóíêöèè COLUMN_NAMES: ' || p_query_answer);*/
  RETURN p_query_answer;
EXCEPTION
  WHEN OTHERS  -- â ðàìêàõ ýòîé çàäà÷è ìîæíî èãíîðèòü âñå îøèáêè
    THEN DBMS_OUTPUT.PUT_LINE(N'Ôóíêöèÿ COLUMN_NAMES íå âåðíóëà çíà÷åíèå èç-çà îøèáêè âî âõîäíûõ ïàðàìåòðàõ');
END;
/


-- ïðèìåðû èñïîëüçîâàíèÿ

SELECT COLUMN_NAMES('select * from nc_sneakers', '<#fh_column#>', ', ') AS func_res FROM dual; -- âåðí¸ò íàçâàíèÿ âñåõ ñòîëáöîâ ÷åðåç çàïÿòóþ èç òàáëèöû nc_sneakers

SELECT COLUMN_NAMES('select * from nc_sneakers', '<#fh_column#> ýòî <#fh_column_number#>-é ñòîëáåö èç <#fh_column_count#>') 
AS func_res FROM dual;			-- âåðí¸ò íàçâàíèÿ âñåõ ñòîëáöîâ èç òàáëèöû nc_sneakers â âèäå: "SN_ID ýòî 1-é ñòîëáåö èç 8" è ò.ä.
