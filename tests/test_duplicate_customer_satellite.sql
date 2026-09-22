SELECT
    CUSTOMER_HK,
    LOAD_DTS,
    HASHDIFF,
    COUNT(*) AS DUPLICATE_COUNT

FROM {{ ref('sat_customer') }}

GROUP BY
    CUSTOMER_HK,
    LOAD_DTS,
    HASHDIFF

HAVING COUNT(*) > 1