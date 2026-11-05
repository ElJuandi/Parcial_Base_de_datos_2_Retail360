-- Retail 360 | R2 | Revisión del modelo de análisis que quedó creado
-- Lista las tablas del esquema dwh con sus columnas, para compararlo con nuestro diseño.
SELECT table_name AS tabla, count(*) AS columnas,
       string_agg(column_name, ', ' ORDER BY ordinal_position) AS lista_columnas
FROM information_schema.columns
WHERE table_schema = 'dwh'
GROUP BY table_name
ORDER BY CASE WHEN table_name LIKE 'dim%' THEN 1 WHEN table_name LIKE 'fact%' THEN 2 ELSE 3 END, table_name;

-- Relaciones: qué hecho apunta a qué dimensión.
SELECT tc.table_name AS desde, kcu.column_name AS columna, ccu.table_name AS hacia
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON kcu.constraint_name = tc.constraint_name AND kcu.table_schema = tc.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'dwh'
ORDER BY 1, 2;
