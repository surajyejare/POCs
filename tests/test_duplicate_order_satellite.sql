SELECT
    ORDER_HK,
    LOAD_DTS,
    HASHDIFF,
    COUNT(*) AS DUPLICATE_COUNT

FROM {{ ref('sat_order') }}

GROUP BY
    ORDER_HK,
    LOAD_DTS,
    HASHDIFF

HAVING COUNT(*) > 1