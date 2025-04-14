WITH companies AS (
    SELECT 
        bloque,
        empresa,
        interes_de_participacion
    FROM {{ source('hydrocarbons_dataset', 'empresas_participantes') }}
),

production AS (
    SELECT 
        bloque,
        SUM(petroleo_mmb * (DATE_DIFF(LAST_DAY(periodo), DATE_TRUNC(periodo, MONTH), DAY) + 1)) AS total_oil_mmb,
        SUM(gas_natural_mmpcd * 0.178 * (DATE_DIFF(LAST_DAY(periodo), DATE_TRUNC(periodo, MONTH), DAY) + 1)) AS total_gas_mmb_equiv,
        SUM((petroleo_mmb + (gas_natural_mmpcd * 0.178)) * (DATE_DIFF(LAST_DAY(periodo), DATE_TRUNC(periodo, MONTH), DAY) + 1)) AS total_boem_equiv
    FROM {{ source('hydrocarbons_dataset', 'produccion_detalle') }}
    WHERE petroleo_mmb IS NOT NULL OR gas_natural_mmpcd IS NOT NULL
    GROUP BY bloque
),

investment AS (
    SELECT 
        bloque,
        SUM(ejercido) AS total_investment_mm_usd
    FROM {{ source('hydrocarbons_dataset', 'inversion_detalle') }}
    GROUP BY bloque
),

base AS (
    SELECT 
        c.empresa,
        c.bloque,
        c.interes_de_participacion,

        pr.total_oil_mmb * c.interes_de_participacion AS oil_by_company,
        pr.total_gas_mmb_equiv * c.interes_de_participacion AS gas_by_company,
        pr.total_boem_equiv * c.interes_de_participacion AS total_by_company,

        inv.total_investment_mm_usd * c.interes_de_participacion AS investment_by_company

    FROM companies c
    LEFT JOIN production pr USING (bloque)
    LEFT JOIN investment inv USING (bloque)
)

SELECT
    empresa AS company,
    SUM(oil_by_company) AS total_oil_mmb,
    SUM(gas_by_company) AS total_gas_mmb_equiv,
    SUM(total_by_company) AS total_boem_equiv,
    SUM(investment_by_company) AS total_investment_mm_usd,

    -- efficiency metrics
    CASE WHEN SUM(investment_by_company) > 0 THEN SUM(oil_by_company) / SUM(investment_by_company) END AS oil_efficiency,
    CASE WHEN SUM(investment_by_company) > 0 THEN SUM(gas_by_company) / SUM(investment_by_company) END AS gas_efficiency,
    CASE WHEN SUM(investment_by_company) > 0 THEN SUM(total_by_company) / SUM(investment_by_company) END AS total_efficiency

FROM base
WHERE total_by_company IS NOT NULL AND investment_by_company IS NOT NULL
GROUP BY company
