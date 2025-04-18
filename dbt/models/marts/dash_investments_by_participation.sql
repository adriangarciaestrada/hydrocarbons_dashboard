WITH filtered_investments AS (
    SELECT
        bloque,
        ano AS year,
        ejercido
    FROM {{ source('your_dataset', 'inversion_detalle') }} --#Change with your BigQuery dataset
    WHERE ejercido IS NOT NULL AND ejercido > 0
),

valid_participations AS (
    SELECT
        bloque,
        empresa,
        interes_de_participacion
    FROM {{ source('your_dataset', 'empresas_participantes') }} --#Change with your BigQuery dataset
    WHERE interes_de_participacion IS NOT NULL
),

bloques_con_participacion AS (
    SELECT DISTINCT bloque FROM valid_participations
),

proportional_with_partners AS (
    SELECT
        inv.year,
        CASE
            WHEN LOWER(TRIM(p.empresa)) LIKE '%pemex%' THEN 'PEMEX'
            ELSE 'Private company'
        END AS operator_class,
        inv.ejercido * p.interes_de_participacion AS invested_amount
    FROM filtered_investments inv
    JOIN bloques_con_participacion bcp
        ON inv.bloque = bcp.bloque
    JOIN valid_participations p
        ON inv.bloque = p.bloque
),

proportional_without_partners AS (
    SELECT
        inv.year,
        'PEMEX' AS operator_class,
        inv.ejercido AS invested_amount
    FROM filtered_investments inv
    LEFT JOIN bloques_con_participacion bcp
        ON inv.bloque = bcp.bloque
    WHERE bcp.bloque IS NULL
),

union_all_cases AS (
    SELECT * FROM proportional_with_partners
    UNION ALL
    SELECT * FROM proportional_without_partners
)

SELECT
    year,
    operator_class,
    ROUND(SUM(invested_amount), 2) AS total_investment_mmusd
FROM union_all_cases
GROUP BY year, operator_class
ORDER BY year, operator_class

