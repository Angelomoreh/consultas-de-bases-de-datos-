-- CASO 1: LISTADO DE TRABAJADORES
SELECT
    -- Alias visibles en el reporte
    t.numrut || '-' || t.dvrut                                    AS RUT_TRABAJADOR,
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) AS NOMBRE_TRABAJADOR,
    UPPER(t.direccion)                                            AS DIRECCION,
    INITCAP(c.nombre_ciudad)                                      AS CIUDAD,
    INITCAP(tt.desc_categoria)                                    AS TIPO_TRABAJADOR,
    UPPER(i.nombre_isapre)                                        AS SISTEMA_SALUD,
    NVL(be.sigla, 'SIN BE')                                       AS NIVEL_ESCOLARIDAD,
    TO_CHAR(ROUND(t.sueldo_base, 0), '$999G999G999')              AS SUELDO_BASE
FROM trabajador t
     JOIN comuna_ciudad   c  ON t.id_ciudad        = c.id_ciudad
     LEFT JOIN tipo_trabajador tt ON t.id_categoria_t   = tt.id_categoria
     JOIN isapre          i  ON t.cod_isapre       = i.cod_isapre
     JOIN bono_escolar    be ON t.id_escolaridad_t = be.id_escolar
WHERE t.sueldo_base BETWEEN 650000 AND 3000000
ORDER BY
    c.nombre_ciudad DESC,
    t.sueldo_base   ASC;


 -- CASO 2: LISTADO DE CAJEROS
  SELECT
    t.numrut || '-' || t.dvrut                                    AS RUT_TRABAJADOR,
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) AS NOMBRE_TRABAJADOR,
    INITCAP(c.nombre_ciudad)                                      AS COMUNA_TRABAJADOR,
    COUNT(tk.nro_ticket)                                          AS CANT_TICKETS_VENDIDOS,
    TO_CHAR(SUM(tk.monto_ticket), '$999G999G999')                 AS TOTAL_VENDIDO,
    TO_CHAR(NVL(SUM(ct.valor_comision), 0), '$999G999G999')       AS COMISION_TOTAL
FROM trabajador       t
     JOIN tipo_trabajador tt ON t.id_categoria_t = tt.id_categoria
     JOIN comuna_ciudad  c  ON t.id_ciudad       = c.id_ciudad
     JOIN tickets_concierto tk ON tk.numrut_t    = t.numrut
     LEFT JOIN comisiones_ticket ct ON ct.nro_ticket = tk.nro_ticket
WHERE UPPER(tt.desc_categoria) = 'CAJERO'
GROUP BY
    t.numrut, t.dvrut,
    t.nombre, t.appaterno, t.apmaterno,
    c.nombre_ciudad
HAVING
    SUM(tk.monto_ticket) > 50000
ORDER BY
    SUM(tk.monto_ticket) DESC;

    
-- CASO 3: LISTADO DE BONIFICACIONES
SELECT
    t.numrut || '-' || t.dvrut                                    AS RUT_TRABAJADOR,
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) AS NOMBRE_TRABAJADOR,
    TO_CHAR(t.fecing, 'YYYY')                                     AS ANIO_INGRESO,
    TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), t.fecing) / 12)          AS ANTIGUEDAD_ANIOS,
    COUNT(af.numrut_carga)                                        AS CANT_CARGAS,
    CASE
        WHEN UPPER(i.nombre_isapre) = 'FONASA' THEN 'FONASA'
        ELSE 'ISAPRE'
    END                                                           AS SISTEMA_SALUD,
    -- Bono por antigüedad (10% o 15%)
    ROUND(
        CASE
            WHEN TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), t.fecing) / 12) <= 10
                THEN t.sueldo_base * 0.10
            ELSE
                t.sueldo_base * 0.15
        END
    , 0)                                                           AS BONO_ANTIGUEDAD,
    -- Bono extra salud (1% si es FONASA)
    ROUND(
        CASE
            WHEN UPPER(i.nombre_isapre) = 'FONASA'
                THEN t.sueldo_base * 0.01
            ELSE
                0
        END
    , 0)                                                           AS BONO_SALUD,
    -- Total de bonos
    ROUND(
        (
            CASE
                WHEN TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), t.fecing) / 12) <= 10
                    THEN t.sueldo_base * 0.10
                ELSE
                    t.sueldo_base * 0.15
            END
        ) +
        (
            CASE
                WHEN UPPER(i.nombre_isapre) = 'FONASA'
                    THEN t.sueldo_base * 0.01
                ELSE
                    0
            END
        )
    , 0)                                                           AS TOTAL_BONO
FROM trabajador t
     JOIN isapre    i   ON t.cod_isapre = i.cod_isapre
     LEFT JOIN asignacion_familiar af ON af.numrut_t = t.numrut
     JOIN est_civil ec ON ec.numrut_t  = t.numrut
WHERE
    (   ec.fecter_estcivil IS NULL
     OR ec.fecter_estcivil > TRUNC(SYSDATE))
GROUP BY
    t.numrut, t.dvrut,
    t.nombre, t.appaterno, t.apmaterno,
    t.fecing,
    t.sueldo_base,
    i.nombre_isapre
ORDER BY
    t.numrut ASC;
