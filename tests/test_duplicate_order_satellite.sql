SELECT
    ORDER_HK,
    HASHDIFF,
    COUNT(*) AS DUPLICATE_COUNT

FROM {{ ref('sat_order') }}

GROUP BY
    ORDER_HK,
    HASHDIFF

HAVING COUNT(*) > 1