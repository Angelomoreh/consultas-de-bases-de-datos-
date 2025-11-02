-- ==============================================
-- CASO 1: ANALISIS DE FACTURAS
-- ==============================================

SELECT
    LPAD(f.rutcliente, 10, '0')                      AS RUT_CLIENTE,
    TO_CHAR(f.fecha, 'DD/MM/YYYY')                   AS FECHA_FACTURA,
    ROUND(f.neto)                                    AS MONTO_NETO,

    CASE
        WHEN f.neto <= 50000 THEN 'Bajo'
        WHEN f.neto BETWEEN 50001 AND 100000 THEN 'Medio'
        ELSE 'Alto'
    END                                              AS CLASIFICACION_MONTO,

    CASE f.codpago
        WHEN 1 THEN 'Efectivo'
        WHEN 2 THEN 'Tarjeta Débito'
        WHEN 3 THEN 'Tarjeta Crédito'
        ELSE 'Cheque'
    END                                              AS FORMA_DE_PAGO

FROM factura f
WHERE EXTRACT(YEAR FROM f.fecha) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -12))
ORDER BY f.fecha DESC, f.neto DESC;

-- ==============================================
-- CASO 2: CLASIFICACION DE CLIENTES
-- ==============================================

SELECT
    RPAD(
        (
            SELECT LISTAGG(SUBSTR(c.rutcliente, LEVEL, 1)) 
                   WITHIN GROUP (ORDER BY LEVEL DESC)
            FROM dual
            CONNECT BY LEVEL <= LENGTH(c.rutcliente)
        ),
        10, '*'
    ) AS RUT_INVERTIDO,
    
    c.nombre,
    NVL(TO_CHAR(c.telefono), 'Sin teléfono') AS TELEFONO,
    CASE 
        WHEN c.codcomuna IS NULL THEN 'Sin comuna'
        ELSE 'Comuna ' || TO_CHAR(c.codcomuna)
    END AS COMUNA,
    NVL(c.mail, 'Correo no registrado') AS CORREO,
    CASE 
        WHEN c.mail IS NULL THEN ''
        ELSE SUBSTR(c.mail, INSTR(c.mail, '@') + 1)
    END AS DOMINIO_CORREO,
    TO_CHAR(c.credito, 'FM999G999G999') AS CREDITO,
    TO_CHAR(c.saldo, 'FM999G999G999') AS SALDO,
    CASE
        WHEN (c.saldo / c.credito) < 0.5
            THEN 'Bueno - Diferencia: ' || TO_CHAR(c.credito - c.saldo, 'FM999G999G999')
        WHEN (c.saldo / c.credito) BETWEEN 0.5 AND 0.8
            THEN 'Regular - Saldo actual: ' || TO_CHAR(c.saldo, 'FM999G999G999')
        ELSE 'Crítico'
    END AS CLASIFICACION

FROM cliente c
WHERE c.estado = 'A'
  AND c.credito > 0
ORDER BY c.nombre ASC;

-- ==============================================
-- CASO 3: STOCK DE PRODUCTOS
-- ==============================================

SELECT
    p.codproducto AS ID_PRODUCTO,
    p.descripcion AS DESCRIPCION,
    p.procedencia AS PROCEDENCIA,

    NVL(TO_CHAR(p.valorcompradolar, 'FM999G999G999'), 'Sin registro') AS VALOR_COMPRA_USD,

    CASE 
        WHEN p.valorcompradolar IS NULL THEN 'Sin registro'
        ELSE TO_CHAR(p.valorcompradolar * &TIPOCAMBIO_DOLAR, 'FM999G999G999')
    END AS VALOR_COMPRA_CLP,

    CASE
        WHEN p.totalstock IS NULL THEN 'Sin datos'
        WHEN p.totalstock < &UMBRAL_BAJO THEN '¡ALERTA stock muy bajo!'
        WHEN p.totalstock BETWEEN &UMBRAL_BAJO AND &UMBRAL_ALTO THEN '¡Reabastecer pronto!'
        ELSE 'OK'
    END AS ALERTA_STOCK,

    CASE
        WHEN p.totalstock > 80 THEN TO_CHAR(p.vunitario * 0.9, 'FM999G999G999')
        ELSE TO_CHAR(p.vunitario, 'FM999G999G999')
    END AS VALOR_CON_DESCUENTO

FROM producto p
WHERE UPPER(p.descripcion) LIKE '%ZAPATO%'
  AND p.procedencia = 'I'
ORDER BY p.codproducto DESC;
