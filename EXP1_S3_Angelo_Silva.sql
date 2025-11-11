-- S3 – CASO 1: CLIENTES POR RANGO DE RENTA 

SELECT
  /* RUT con puntos y guion desde NUMRUT_CLI + DVRUT_CLI */
  REGEXP_REPLACE(
    REGEXP_REPLACE(TO_CHAR(c.numrut_cli) || '-' || c.dvrut_cli, '[^0-9Kk-]', ''),
    '^(\d{1,2})(\d{3})(\d{3})-([0-9Kk])$', '\1.\2.\3-\4'
  ) AS RUT,

  /* Nombre completo con capitalización */
  INITCAP(
    TRIM(c.nombre_cli || ' ' || c.appaterno_cli || ' ' || c.apmaterno_cli)
  ) AS NOMBRE_COMPLETO,

  /* Renta con separador de miles y símbolo $ */
  TO_CHAR(c.renta_cli, 'FM$999G999G999') AS RENTA,

  /* Tramo de renta */
  CASE
    WHEN c.renta_cli > 500000 THEN 'TRAMO 1'
    WHEN c.renta_cli BETWEEN 400000 AND 500000 THEN 'TRAMO 2'
    WHEN c.renta_cli BETWEEN 200000 AND 399999 THEN 'TRAMO 3'
    ELSE 'TRAMO 4'
  END AS TRAMO

FROM cliente c
WHERE c.renta_cli BETWEEN &RENTA_MINIMA AND &RENTA_MAXIMA
  AND c.celular_cli IS NOT NULL
  AND c.celular_cli > 0
ORDER BY NOMBRE_COMPLETO ASC;


-- S3 – CASO 2: Sueldo promedio por categoría y sucursal
-- Agrupa por categoría y sucursal, cuenta empleados y filtra por AVG >= &SUELDO_PROMEDIO_MINIMO

SELECT
  ce.DESC_CATEGORIA_EMP                         AS CATEGORIA,
  s.DESC_SUCURSAL                               AS SUCURSAL,
  COUNT(*)                                      AS CANT_EMPLEADOS,
  TO_CHAR(AVG(e.SUELDO_EMP), 'FM$999G999G999D00') AS SUELDO_PROMEDIO
FROM EMPLEADO e
JOIN CATEGORIA_EMPLEADO ce
  ON ce.ID_CATEGORIA_EMP = e.ID_CATEGORIA_EMP
JOIN SUCURSAL s
  ON s.ID_SUCURSAL = e.ID_SUCURSAL
GROUP BY
  ce.DESC_CATEGORIA_EMP, s.DESC_SUCURSAL
HAVING
  AVG(e.SUELDO_EMP) >= &SUELDO_PROMEDIO_MINIMO
ORDER BY
  AVG(e.SUELDO_EMP) DESC;

-- S3 – CASO 3: Arriendo promedio por tipo de propiedad

SELECT
  tp.DESC_TIPO_PROPIEDAD                               AS TIPO_PROPIEDAD,
  COUNT(*)                                             AS TOTAL_PROPIEDADES,
  TO_CHAR(AVG(p.VALOR_ARRIENDO), 'FM$999G999G999D00')  AS PROM_ARRIENDO,
  ROUND(AVG(p.SUPERFICIE), 2)                          AS PROM_SUPERFICIE_M2,
  TO_CHAR(
    AVG(p.VALOR_ARRIENDO) / NULLIF(AVG(p.SUPERFICIE), 0),
    'FM$999G999D00'
  )                                                    AS ARR_X_M2,
  CASE
    WHEN (AVG(p.VALOR_ARRIENDO) / NULLIF(AVG(p.SUPERFICIE), 0)) < 5000
      THEN 'Económico'
    WHEN (AVG(p.VALOR_ARRIENDO) / NULLIF(AVG(p.SUPERFICIE), 0)) BETWEEN 5000 AND 10000
      THEN 'Medio'
    ELSE 'Alto'
  END                                                  AS CATEGORIA_M2
FROM PROPIEDAD p
JOIN TIPO_PROPIEDAD tp
  ON tp.ID_TIPO_PROPIEDAD = p.ID_TIPO_PROPIEDAD
GROUP BY tp.DESC_TIPO_PROPIEDAD
HAVING (AVG(p.VALOR_ARRIENDO) / NULLIF(AVG(p.SUPERFICIE), 0)) > 1000
ORDER BY (AVG(p.VALOR_ARRIENDO) / NULLIF(AVG(p.SUPERFICIE), 0)) DESC;


