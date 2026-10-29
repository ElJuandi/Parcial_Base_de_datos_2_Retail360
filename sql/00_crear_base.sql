-- RETAIL 360 | 00 | Crear base de datos del ejercicio.
-- PRERREQUISITOS: abrir psql conectado a postgres (NO a retail360), con permiso CREATEDB.
-- EJECUCION: psql -X -v ON_ERROR_STOP=1 -d postgres -f sql/00_crear_base.sql
-- No ejecutar si ya existe retail360. No se borran otras bases.
CREATE DATABASE retail360 WITH ENCODING 'UTF8';
-- VALIDAR DESPUES: psql -X -d retail360 -c "SELECT current_database(), version();"
