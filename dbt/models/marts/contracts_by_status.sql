WITH filtered_contracts AS (
    SELECT DISTINCT bloque, estatus
    FROM {{ source('hydrocarbons_dataset', 'inversion_detalle') }}
    WHERE LOWER(regimen) = 'contrato'
)

SELECT
    estatus AS Status,
    COUNT(*) AS Total_Contracts
FROM filtered_contracts
GROUP BY estatus
ORDER BY Total_Contracts DESC