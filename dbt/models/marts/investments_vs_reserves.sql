WITH reservas AS (
    SELECT 
        bloque,
        categoria,
        EXTRACT(YEAR FROM fecha) AS year,
        SUM(petroleo_mmb) AS oil_mmb,
        SUM(gas_mmmpc * 0.178) AS gas_mmb_equiv,
        SUM(petroleo_mmb + gas_mmmpc * 0.178) AS total_mmb_equiv
    FROM {{ source('hydrocarbons_dataset', 'reservas_detalle') }}
    WHERE categoria = '2P'
    GROUP BY bloque, categoria, EXTRACT(YEAR FROM fecha)
),

reservas_con_cambio AS (
    SELECT 
        bloque,
        year,
        total_mmb_equiv,
        total_mmb_equiv - LAG(total_mmb_equiv) OVER (PARTITION BY bloque ORDER BY year) AS reservas_incremento_mmb
    FROM reservas
),

bloques_con_extraccion AS (
    SELECT DISTINCT bloque
    FROM {{ source('hydrocarbons_dataset', 'inversion_detalle') }}
    WHERE actividad = 'EXTRACCION'
),

exploracion_inversion AS (
    SELECT 
        bloque,
        ano AS year,
        SUM(ejercido) AS inversion_exploracion_mm_usd
    FROM {{ source('hydrocarbons_dataset', 'inversion_detalle') }}
    WHERE actividad = 'EXPLORACION'
    GROUP BY bloque, ano
),

base AS (
    SELECT 
        r.bloque,
        r.year,
        r.reservas_incremento_mmb,
        i.inversion_exploracion_mm_usd
    FROM reservas_con_cambio r
    LEFT JOIN exploracion_inversion i 
        ON r.bloque = i.bloque AND r.year = i.year
    WHERE r.bloque IN (SELECT bloque FROM bloques_con_extraccion)
)

SELECT 
    bloque,
    SUM(reservas_incremento_mmb) AS total_reservas_incremento_mmb,
    SUM(inversion_exploracion_mm_usd) AS total_inversion_exploracion_mm_usd,
    CASE 
        WHEN SUM(inversion_exploracion_mm_usd) > 0 
        THEN SUM(reservas_incremento_mmb) / SUM(inversion_exploracion_mm_usd)
    END AS exploration_effectiveness
FROM base
WHERE reservas_incremento_mmb IS NOT NULL
GROUP BY bloque
ORDER BY exploration_effectiveness DESC
