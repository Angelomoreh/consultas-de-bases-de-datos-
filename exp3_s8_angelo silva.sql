--------------------------------------------------------------------------------
-- PRY2205 EXP3 S8
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ADMIN / SYS / SYSTEM
--------------------------------------------------------------------------------
CREATE USER PRY2205_USER1 IDENTIFIED BY "Usr1_Pry2205"
DEFAULT TABLESPACE DATA
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON DATA;

CREATE USER PRY2205_USER2 IDENTIFIED BY "Usr2_Pry2205"
DEFAULT TABLESPACE DATA
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON DATA;

CREATE ROLE PRY2205_ROL_D;
CREATE ROLE PRY2205_ROL_P;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE INDEX, CREATE SYNONYM TO PRY2205_ROL_D;
GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE, CREATE TRIGGER TO PRY2205_ROL_P;


-- GRANT CREATE PUBLIC SYNONYM TO PRY2205_ROL_D;

GRANT PRY2205_ROL_D TO PRY2205_USER1;
GRANT PRY2205_ROL_P TO PRY2205_USER2;

--------------------------------------------------------------------------------
-- PRY2205_USER1
--------------------------------------------------------------------------------
CONN PRY2205_USER1/Usr1_Pry2205

ALTER SESSION SET NLS_DATE_FORMAT='DD/MM/YYYY';
ALTER SESSION SET NLS_NUMERIC_CHARACTERS=',.';

-- script oficial de creación + poblado 
@PRY2205_Exp3_S8_CreaEsquemaPoblado (forma C).sql

-- CASO 1: SINÓNIMOS
CREATE OR REPLACE PUBLIC SYNONYM S_LIBRO     FOR PRY2205_USER1.LIBRO;
CREATE OR REPLACE PUBLIC SYNONYM S_EJEMPLAR  FOR PRY2205_USER1.EJEMPLAR;
CREATE OR REPLACE PUBLIC SYNONYM S_PRESTAMO  FOR PRY2205_USER1.PRESTAMO;
CREATE OR REPLACE PUBLIC SYNONYM S_ALUMNO    FOR PRY2205_USER1.ALUMNO;
CREATE OR REPLACE PUBLIC SYNONYM S_CARRERA   FOR PRY2205_USER1.CARRERA;
CREATE OR REPLACE PUBLIC SYNONYM S_REBAJA    FOR PRY2205_USER1.REBAJA_MULTA;

-- menor privilegio: dar SELECT al ROL_P (no al user)
GRANT SELECT ON PRY2205_USER1.LIBRO        TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.EJEMPLAR     TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.PRESTAMO     TO PRY2205_ROL_P;

-- CASO 3.1: VISTA VW_DETALLE_MULTAS (por sinónimos)
CREATE OR REPLACE VIEW VW_DETALLE_MULTAS AS
SELECT
  p.prestamoid                                              AS id_prestamo,
  INITCAP(a.nombre||' '||a.apaterno||' '||a.amaterno)       AS nombre_alumno,
  c.descripcion                                             AS nombre_carrera,
  p.libroid                                                 AS id_libro,
  l.precio                                                  AS valor_libro,
  p.fecha_termino                                           AS fecha_termino,
  p.fecha_entrega                                           AS fecha_entrega,
  (p.fecha_entrega - p.fecha_termino)                       AS dias_atraso,
  ROUND(l.precio * 0.03 * (p.fecha_entrega - p.fecha_termino))                 AS valor_multa,
  ROUND(NVL(r.porc_rebaja_multa,0) / 100, 2)                                  AS porcentaje_rebaja_multa,
  ROUND(
    ROUND(l.precio * 0.03 * (p.fecha_entrega - p.fecha_termino)) *
    (1 - (NVL(r.porc_rebaja_multa,0) / 100))
  )                                                        AS valor_rebajado
FROM S_PRESTAMO p
JOIN S_LIBRO   l ON l.libroid   = p.libroid
JOIN S_ALUMNO  a ON a.alumnoid  = p.alumnoid
JOIN S_CARRERA c ON c.carreraid = a.carreraid
LEFT JOIN S_REBAJA r ON r.carreraid = c.carreraid
WHERE p.fecha_entrega > p.fecha_termino
  AND EXTRACT(YEAR FROM p.fecha_termino) = EXTRACT(YEAR FROM SYSDATE) - 2
ORDER BY p.fecha_entrega DESC;

-- CASO 3.2: ÍNDICES (mínimos útiles para la vista)
CREATE INDEX IDX_PRESTAMO_FT_FE ON PRESTAMO (fecha_termino, fecha_entrega);
CREATE INDEX IDX_PRESTAMO_ALU   ON PRESTAMO (alumnoid);
CREATE INDEX IDX_PRESTAMO_LIB   ON PRESTAMO (libroid);
CREATE INDEX IDX_ALUMNO_CARR    ON ALUMNO (carreraid);

--------------------------------------------------------------------------------
-- PRY2205_USER2
--------------------------------------------------------------------------------
CONN PRY2205_USER2/Usr2_Pry2205
ALTER SESSION SET NLS_NUMERIC_CHARACTERS=',.';

-- CASO 2: SEQ_CONTROL_STOCK
CREATE SEQUENCE SEQ_CONTROL_STOCK START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- CASO 2: CONTROL_STOCK_LIBROS (CTAS sin WITH, usando sinónimos)
CREATE TABLE CONTROL_STOCK_LIBROS AS
SELECT
  SEQ_CONTROL_STOCK.NEXTVAL                                  AS id_control,
  l.libroid                                                  AS libro_id,
  l.nombre_libro                                             AS nombre_libro,
  COUNT(e.ejemplarid)                                        AS total_ejemplares,
  COUNT(DISTINCT p.ejemplarid)                               AS en_prestamo,
  COUNT(e.ejemplarid) - COUNT(DISTINCT p.ejemplarid)         AS disponibles,
  ROUND(
    (COUNT(DISTINCT p.ejemplarid) / NULLIF(COUNT(e.ejemplarid),0)) * 100
  , 2)                                                       AS porcentaje_prestamo,
  CASE
    WHEN (COUNT(e.ejemplarid) - COUNT(DISTINCT p.ejemplarid)) > 2 THEN 'S'
    ELSE 'N'
  END                                                        AS stock_critico
FROM S_LIBRO l
JOIN S_EJEMPLAR e
  ON e.libroid = l.libroid
LEFT JOIN S_PRESTAMO p
  ON p.libroid = l.libroid
 AND p.empleadoid IN (190,180,150)
 AND p.fecha_inicio >= ADD_MONTHS(TRUNC(SYSDATE,'MM'), -24)
 AND p.fecha_inicio <  ADD_MONTHS(TRUNC(SYSDATE,'MM'), -23)
GROUP BY l.libroid, l.nombre_libro
ORDER BY l.libroid;

COMMIT;
