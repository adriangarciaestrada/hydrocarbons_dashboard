WITH filtered_investments AS (
    SELECT
        bloque,
        ano AS year,
        ejercido
    FROM {{ source('hydrocarbons_dataset', 'inversion_detalle') }}
    WHERE ejercido IS NOT NULL AND ejercido > 0
),

-- Participaciones válidas para bloques con múltiples empresas
valid_participations AS (
    SELECT
        bloque,
        empresa,
        interes_de_participacion
    FROM {{ source('hydrocarbons_dataset', 'empresas_participantes') }}
    WHERE interes_de_participacion IS NOT NULL
),

-- Bloques que tienen registros en empresas_participantes
bloques_con_participacion AS (
    SELECT DISTINCT bloque FROM valid_participations
),

-- Cálculo proporcional para bloques con varias empresas
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

-- Cálculo completo de inversión asignada a PEMEX cuando no hay socios
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

-- Unión final de ambos casos
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

