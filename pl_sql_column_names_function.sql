CREATE OR REPLACE FUNCTION COLUMN_NAMES
  ( p_query IN CLOB,
    p_format CLOB,
    p_separator IN VARCHAR2 DEFAULT CHR(13)||CHR(10) 
  ) RETURN CLOB
IS
  p_query_out         CLOB;              -- переменная для модифицирования p_query  (т.к. она должна быть в режиме IN)
  p_format_out        CLOB;              -- переменная для модифицирования p_format (т.к. она должна быть в режиме IN)
  tag_2_qty           NUMBER;            -- кол-во тегов во втором параметре p_format 
  cur_fh              PLS_INTEGER;       -- идентификатор курсора
  col_qty_fh          PLS_INTEGER;       -- сюда запишется кол-во столбцов запроса
  col_names_coll_fh   DBMS_SQL.DESC_TAB; -- коллекция с именами столбцов
  p_query_answer      CLOB;              -- ответ, который возвращает функция  
BEGIN
  -- очистка от возможных двойных кавычек
  p_query_out  := REPLACE(p_query, q'['']', q'[']');
  p_format_out := REPLACE(p_format, q'['']', q'[']');
    DBMS_OUTPUT.PUT_LINE(N'После очистки от двойных кавычек (даже если их не было) p_query_out = ' || p_query_out);
    DBMS_OUTPUT.PUT_LINE(N'После очистки от двойных кавычек (даже если их не было) p_format_out = ' || p_format_out);
    DBMS_OUTPUT.PUT_LINE('= = = = = = = = = ='); 
  -- извлечение имён столбцов
  cur_fh := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(cur_fh, p_query_out, DBMS_SQL.NATIVE);
  DBMS_SQL.DESCRIBE_COLUMNS (cur_fh, col_qty_fh, col_names_coll_fh);
  -- обработка второго параметра p_format
  tag_2_qty := REGEXP_COUNT(p_format_out, '<#[^#]*#>');
  -- получение итоговой строки-ответа
  FOR i IN 1..col_names_coll_fh.LAST 
  LOOP
    IF tag_2_qty > 0
      THEN
        FOR x IN 1..tag_2_qty LOOP
          IF LOWER(REGEXP_REPLACE(REGEXP_SUBSTR(p_format, '<#[^#]+#>', 1, x), '<#([^#]+)#>', '\1') ) = 'fh_column'				-- fh_column это имя столбца
            THEN p_format_out := REGEXP_REPLACE(p_format_out, '([^<]*)<#' || 'fh_column' || '#>(.*)', 
                                                '\1' || col_names_coll_fh(i).col_name || '\2', 1, 1, 'i');
              DBMS_OUTPUT.PUT_LINE(N'На ' || i || N'-м проходе (i) шага № ' || x || N' (x) была замена fh_column и p_format_out = ' || p_format_out);
          ELSIF LOWER(REGEXP_REPLACE(REGEXP_SUBSTR(p_format, '<#[^#]+#>', 1, x), '<#([^#]+)#>', '\1') ) = 'fh_column_number'	-- fh_column_number это порядковый номер столбца в запросе
            THEN p_format_out := REGEXP_REPLACE(p_format_out, '([^<]*)<#' || 'fh_column_number' || '#>(.*)', 
                                                '\1' || i || '\2', 1, 1, 'i');
              DBMS_OUTPUT.PUT_LINE(N'На ' || i || N'-м проходе (i) шага № ' || x || N' (x) была замена fh_column_number и p_format_out = ' || p_format_out);
          ELSIF LOWER(REGEXP_REPLACE(REGEXP_SUBSTR(p_format, '<#[^#]+#>', 1, x), '<#([^#]+)#>', '\1') ) = 'fh_column_count'		-- fh_column_count это общее кол-во столбцов в запросе
            THEN p_format_out := REGEXP_REPLACE(p_format_out, '([^<]*)<#' || 'fh_column_count' || '#>(.*)', 
                                                '\1' || col_names_coll_fh.LAST || '\2', 1, 1, 'i');
              DBMS_OUTPUT.PUT_LINE(N'На ' || i || N'-м проходе (i) шага № ' || x || N' (x) была замена fh_column_count и p_format_out = ' || p_format_out);
          ELSE NULL;
          END IF;
        END LOOP;
      p_query_answer := p_query_answer || p_format_out || p_separator;
      p_format_out := REPLACE(p_format, q'['']', q'[']');
      ELSE NULL;
    END IF;
  END LOOP;
  p_query_answer := RTRIM(p_query_answer, p_separator);
    /*DBMS_OUTPUT.PUT_LINE(N'Результат функции COLUMN_NAMES: ' || p_query_answer);*/
  RETURN p_query_answer;
EXCEPTION
  WHEN OTHERS  -- в рамках этой задачи можно игнорить все ошибки
    THEN DBMS_OUTPUT.PUT_LINE(N'Функция COLUMN_NAMES не вернула значение из-за ошибки во входных параметрах');
END;
/


-- примеры использования

SELECT COLUMN_NAMES('select * from nc_sneakers', '<#fh_column#>', ', ') AS func_res FROM dual; -- вернёт названия всех столбцов через запятую из таблицы nc_sneakers

SELECT COLUMN_NAMES('select * from nc_sneakers', '<#fh_column#> это <#fh_column_number#>-й столбец из <#fh_column_count#>') 
AS func_res FROM dual;			-- вернёт названия всех столбцов из таблицы nc_sneakers в виде: "SN_ID это 1-й столбец из 8" и т.д. 