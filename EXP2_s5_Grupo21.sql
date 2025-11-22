--- caso 1: Listado de clientes

SELECT
  TO_CHAR(c.numrun) || '-' || c.dvrun AS RUT_CLIENTE,
  INITCAP(
    c.pnombre
    || ' '
    || NVL(c.snombre || ' ', '')
    || c.appaterno
    || ' '
    || NVL(c.apmaterno, '')
  ) AS NOMBRE_CLIENTE,
  INITCAP(p.nombre_prof_ofic) AS PROFESION_OFICIO,
  INITCAP(tc.nombre_tipo_cliente) AS TIPO_CLIENTE,
  EXTRACT(YEAR FROM c.fecha_inscripcion) AS ANIO_INSCRIPCION
FROM cliente c
JOIN profesion_oficio p
  ON c.cod_prof_ofic = p.cod_prof_ofic
JOIN tipo_cliente tc
  ON c.cod_tipo_cliente = tc.cod_tipo_cliente
WHERE tc.nombre_tipo_cliente = 'Trabajadores dependientes'
  AND p.nombre_prof_ofic IN ('Contador', 'Vendedor')
  AND EXTRACT(YEAR FROM c.fecha_inscripcion) >
      (SELECT ROUND(AVG(EXTRACT(YEAR FROM fecha_inscripcion)))
       FROM cliente)
ORDER BY c.numrun ASC;

--- caso 2 : Aunmento de credito 

CREATE TABLE CLIENTES_CUPOS_COMPRA AS
SELECT
  TO_CHAR(c.numrun) || '-' || c.dvrun AS RUT_CLIENTE,
  TRUNC(MONTHS_BETWEEN(SYSDATE, c.fecha_nacimiento) / 12) AS EDAD,
  t.cupo_disp_compras AS CUPO_DISPONIBLE_COMPRAS
FROM cliente c
JOIN tarjeta_cliente t
  ON c.numrun = t.numrun
WHERE t.cupo_disp_compras >= (
  SELECT MAX(t2.cupo_disp_compras)
  FROM tarjeta_cliente t2
  WHERE EXTRACT(YEAR FROM t2.fecha_cupo) = EXTRACT(YEAR FROM SYSDATE) - 1
)
ORDER BY EDAD ASC;

