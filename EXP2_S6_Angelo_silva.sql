--- caso 1: Reporteria de asesorias

SELECT
    t.id_profesional,
    t.nombre_completo,
    SUM(CASE WHEN t.sector = 'BANCA'  THEN t.cant_asesorias    ELSE 0 END) AS banco_cant,
    SUM(CASE WHEN t.sector = 'BANCA'  THEN t.total_honorarios  ELSE 0 END) AS banco_total,
    SUM(CASE WHEN t.sector = 'RETAIL' THEN t.cant_asesorias    ELSE 0 END) AS retail_cant,
    SUM(CASE WHEN t.sector = 'RETAIL' THEN t.total_honorarios  ELSE 0 END) AS retail_total,
    SUM(t.cant_asesorias) AS total_asesorias,
    SUM(t.total_honorarios) AS total_honorarios
FROM (
    SELECT 
        p.id_profesional,
        p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS nombre_completo,
        'BANCA' AS sector,
        COUNT(*) AS cant_asesorias,
        SUM(a.honorario) AS total_honorarios
    FROM profesional p
    JOIN asesoria a ON p.id_profesional = a.id_profesional
    JOIN empresa e ON a.cod_empresa = e.cod_empresa
    WHERE e.cod_sector = 3
    GROUP BY p.id_profesional, p.appaterno, p.apmaterno, p.nombre

    UNION ALL

    SELECT 
        p.id_profesional,
        p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS nombre_completo,
        'RETAIL' AS sector,
        COUNT(*) AS cant_asesorias,
        SUM(a.honorario) AS total_honorarios
    FROM profesional p
    JOIN asesoria a ON p.id_profesional = a.id_profesional
    JOIN empresa e ON a.cod_empresa = e.cod_empresa
    WHERE e.cod_sector = 4
    GROUP BY p.id_profesional, p.appaterno, p.apmaterno, p.nombre
) t
GROUP BY
    t.id_profesional,
    t.nombre_completo
HAVING 
    SUM(CASE WHEN t.sector = 'BANCA'  THEN t.cant_asesorias ELSE 0 END) > 0
AND SUM(CASE WHEN t.sector = 'RETAIL' THEN t.cant_asesorias ELSE 0 END) > 0
ORDER BY t.id_profesional;

--- caso 2 : Resumen de honorarios 

DROP TABLE REPORTE_MES CASCADE CONSTRAINTS;

CREATE TABLE REPORTE_MES (
    id_profesional    NUMBER(10),
    nombre_completo   VARCHAR2(60),
    profesion         VARCHAR2(40),
    comuna            VARCHAR2(40),
    cant_asesorias    NUMBER,
    total_honorarios  NUMBER,
    prom_honorarios   NUMBER,
    min_honorario     NUMBER,
    max_honorario     NUMBER
);

INSERT INTO REPORTE_MES
SELECT
    p.id_profesional,
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS nombre_completo,
    pr.nombre_profesion AS profesion,
    c.nom_comuna AS comuna,
    COUNT(a.id_profesional) AS cant_asesorias,
    ROUND(SUM(a.honorario)) AS total_honorarios,
    ROUND(AVG(a.honorario)) AS prom_honorarios,
    ROUND(MIN(a.honorario)) AS min_honorario,
    ROUND(MAX(a.honorario)) AS max_honorario
FROM profesional p
JOIN profesion pr ON p.cod_profesion = pr.cod_profesion
JOIN comuna c ON p.cod_comuna = c.cod_comuna
JOIN asesoria a ON p.id_profesional = a.id_profesional
WHERE TO_CHAR(a.fin_asesoria, 'MM') = '04'
  AND TO_CHAR(a.fin_asesoria, 'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE, -12), 'YYYY')
GROUP BY 
    p.id_profesional,
    p.appaterno,
    p.apmaterno,
    p.nombre,
    pr.nombre_profesion,
    c.nom_comuna
ORDER BY p.id_profesional;

COMMIT;

--- caso 3 : Modificacion de honorarios 

SELECT
    p.id_profesional,
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS nombre_completo,
    SUM(a.honorario) AS total_honorarios_marzo,
    p.sueldo AS sueldo_actual
FROM profesional p
JOIN asesoria a ON p.id_profesional = a.id_profesional
WHERE TO_CHAR(a.fin_asesoria, 'MM') = '03'
  AND TO_CHAR(a.fin_asesoria, 'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE, -12), 'YYYY')
GROUP BY
    p.id_profesional,
    p.appaterno,
    p.apmaterno,
    p.nombre,
    p.sueldo
ORDER BY p.id_profesional;

UPDATE profesional p
SET sueldo =
    CASE
        WHEN (SELECT SUM(a.honorario)
              FROM asesoria a
              WHERE a.id_profesional = p.id_profesional
                AND TO_CHAR(a.fin_asesoria, 'MM') = '03'
                AND TO_CHAR(a.fin_asesoria, 'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE, -12), 'YYYY')
             ) < 1000000
        THEN ROUND(p.sueldo * 1.10)
        ELSE ROUND(p.sueldo * 1.15)
    END
WHERE p.id_profesional IN (
    SELECT a.id_profesional
    FROM asesoria a
    WHERE TO_CHAR(a.fin_asesoria, 'MM') = '03'
      AND TO_CHAR(a.fin_asesoria, 'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE, -12), 'YYYY')
    GROUP BY a.id_profesional
);

COMMIT;

SELECT
    p.id_profesional,
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS nombre_completo,
    SUM(a.honorario) AS total_honorarios_marzo,
    p.sueldo AS sueldo_actual
FROM profesional p
JOIN asesoria a ON p.id_profesional = a.id_profesional
WHERE TO_CHAR(a.fin_asesoria, 'MM') = '03'
  AND TO_CHAR(a.fin_asesoria, 'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE, -12), 'YYYY')
GROUP BY
    p.id_profesional,
    p.appaterno,
    p.apmaterno,
    p.nombre,
    p.sueldo
ORDER BY p.id_profesional;
