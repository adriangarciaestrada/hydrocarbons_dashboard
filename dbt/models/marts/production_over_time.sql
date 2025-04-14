SELECT
    DATE_TRUNC(periodo, MONTH) AS month,
    SUM(petroleo_mmb) AS total_oil_kbbl,
    SUM(condensado_mbd) AS total_condensate_kbbl,
    SUM(gas_natural_mmpcd) AS total_gas_mmscf
FROM {{ source('hydrocarbons_dataset', 'produccion_detalle') }}
WHERE periodo IS NOT NULL
GROUP BY month
ORDER BY month