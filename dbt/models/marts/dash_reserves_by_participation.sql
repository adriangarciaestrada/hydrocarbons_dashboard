WITH reservas_filtradas AS (
    SELECT
        CAST(fecha AS DATE) AS fecha,
        FORMAT_DATE('%Y', DATE(fecha)) AS year,
        bloque,
        categoria,
        petroleo_mmb,
        gas_mmmpc
    FROM {{ source('your_dataset', 'reservas_detalle') }} --#Change with your BigQuery dataset
    WHERE categoria = '2P'
),

participaciones_validas AS (
    SELECT
        bloque,
        empresa AS operator,
        interes_de_participacion
    FROM {{ source('your_dataset', 'empresas_participantes') }} --#Change with your BigQuery dataset
    WHERE interes_de_participacion IS NOT NULL
),

bloques_participados AS (
    SELECT DISTINCT bloque FROM participaciones_validas
),

proporcional_union AS (
    SELECT
        r.year,
        r.bloque,
        CASE
            WHEN LOWER(TRIM(p.operator)) LIKE '%pemex%' THEN 'PEMEX'
            ELSE 'Private company'
        END AS operator_class,
        r.petroleo_mmb * p.interes_de_participacion AS oil_reserves,
        r.gas_mmmpc * p.interes_de_participacion AS gas_reserves
    FROM reservas_filtradas r
    INNER JOIN participaciones_validas p
        ON r.bloque = p.bloque

    UNION ALL

    SELECT
        r.year,
        r.bloque,
        'PEMEX' AS operator_class,
        r.petroleo_mmb,
        r.gas_mmmpc
    FROM reservas_filtradas r
    LEFT JOIN bloques_participados b
        ON r.bloque = b.bloque
    WHERE b.bloque IS NULL
),

agrupado AS (
    SELECT
        year,
        operator_class,
        ROUND(SUM(oil_reserves), 2) AS total_oil_reserves,
        ROUND(SUM(gas_reserves), 2) AS total_gas_reserves
    FROM proporcional_union
    GROUP BY year, operator_class
)

SELECT *
FROM agrupado
ORDER BY year, operator_class
