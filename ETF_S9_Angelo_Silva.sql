-- EVALUACION FINAL TRASNVERSAL - CONSULTAS DE BASES DE DATOS - Angelo Silva 
-- Verificar tablas disponibles
SELECT table_name
FROM user_tables
ORDER BY table_name;

-- caso 2 informe de remuneraciones 

INSERT INTO CARTOLA_PROFESIONALES
SELECT
    p.RUTPROF                                       AS rut_profesional,
    p.NOMPRO || ' ' || p.APPPRO || ' ' || p.APMPRO  AS nombre_profesional,
    pr.NOMPROFESION                                 AS profesion,
    i.NOMISAPRE                                     AS isapre,
    p.SUELDO                                       AS sueldo_base,
    NVL(p.COMISION,0)                               AS porc_comision_profesional,
    ROUND(p.SUELDO * NVL(p.COMISION,0) / 100)      AS valor_total_comision,
    rs.HONOR_PCT                                    AS porcentaje_honorario,
    CASE
        WHEN tc.NOMTCONTRATO = 'INDEFINIDO' THEN 150000
        WHEN tc.NOMTCONTRATO = 'PLAZO FIJO' THEN 60000
        WHEN tc.NOMTCONTRATO = 'HONORARIOS' THEN 50000
        ELSE 0
    END                                             AS bono_movilizacion,
    ROUND(
        p.SUELDO
        + (p.SUELDO * NVL(p.COMISION,0) / 100)
        + (p.SUELDO * rs.HONOR_PCT / 100)
        + CASE
            WHEN tc.NOMTCONTRATO = 'INDEFINIDO' THEN 150000
            WHEN tc.NOMTCONTRATO = 'PLAZO FIJO' THEN 60000
            WHEN tc.NOMTCONTRATO = 'HONORARIOS' THEN 50000
            ELSE 0
          END
    )                                               AS total_pagar
FROM PROFESIONAL p
JOIN PROFESION pr        ON pr.IDPROFESION = p.IDPROFESION
JOIN ISAPRE i            ON i.IDISAPRE = p.IDISAPRE
JOIN TIPO_CONTRATO tc    ON tc.IDTCONTRATO = p.IDTCONTRATO
JOIN RANGOS_SUELDOS rs   ON p.SUELDO BETWEEN rs.S_MIN AND rs.S_MAX
ORDER BY
    pr.NOMPROFESION,
    p.SUELDO DESC,
    p.COMISION,
    p.RUTPROF;

-- verificacion caso 2: 
SELECT COUNT(*) AS total_registros
FROM CARTOLA_PROFESIONALES;

-- caso 3,1 :

CREATE OR REPLACE VIEW VW_EMPRESAS_ASESORADAS AS
SELECT
    e.RUT_EMPRESA || '-' || e.DV_EMPRESA                    AS rut_empresa,
    e.NOMEMPRESA                                           AS nombre_empresa,
    TRUNC(MONTHS_BETWEEN(SYSDATE, e.FECHA_INICIACION_ACTIVIDADES)/12)
                                                           AS antiguedad_anios,
    e.IVA_DECLARADO                                        AS iva_declarado,
    ROUND(COUNT(a.INICIO) / 12, 2)                          AS promedio_asesorias,
    ROUND(e.IVA_DECLARADO * (COUNT(a.INICIO) / 12) / 100)  AS devolucion_iva_estimada,
    CASE
        WHEN COUNT(a.INICIO)/12 > 5 THEN 'CLIENTE PREMIUM'
        WHEN COUNT(a.INICIO)/12 BETWEEN 3 AND 5 THEN 'CLIENTE'
        ELSE 'CLIENTE POCO CONCURRIDO'
    END                                                    AS tipo_cliente,
    CASE
        WHEN COUNT(a.INICIO) >= 7 THEN '1 ASESORIA GRATIS'
        WHEN COUNT(a.INICIO) BETWEEN 5 AND 6 THEN '1 ASESORIA 40% DESCUENTO'
        WHEN COUNT(a.INICIO) = 5 THEN '1 ASESORIA 30% DESCUENTO'
        ELSE 'CAPTAR CLIENTE'
    END                                                    AS promocion
FROM EMPRESA e
JOIN ASESORIA a ON a.IDEMPRESA = e.IDEMPRESA
WHERE EXTRACT(YEAR FROM a.FIN) = EXTRACT(YEAR FROM SYSDATE) - 1
GROUP BY
    e.RUT_EMPRESA,
    e.DV_EMPRESA,
    e.NOMEMPRESA,
    e.FECHA_INICIACION_ACTIVIDADES,
    e.IVA_DECLARADO
ORDER BY
    e.NOMEMPRESA;

-- verificacion caso 3.1(vista):

SELECT COUNT(*) AS empresas_en_vista
FROM VW_EMPRESAS_ASESORADAS;

-- caso 3,2: optimizasion con indices; 

CREATE INDEX IDX_ASESORIA_EMPRESA ON ASESORIA(IDEMPRESA);
CREATE INDEX IDX_ASESORIA_FIN     ON ASESORIA(FIN);

-- verificacion de indices:
SELECT index_name, table_name
FROM user_indexes
WHERE table_name = 'ASESORIA';

-- confirmacion general :
SELECT
  (SELECT COUNT(*) FROM CARTOLA_PROFESIONALES) AS cartolas,
  (SELECT COUNT(*) FROM VW_EMPRESAS_ASESORADAS) AS empresas_asesoradas
FROM dual;
