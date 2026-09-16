SELECT
    CUSTOMER_HK,
    HASHDIFF,
    COUNT(*) AS DUPLICATE_COUNT

FROM {{ ref('sat_customer') }}

GROUP BY
    CUSTOMER_HK,
    HASHDIFF

HAVING COUNT(*) > 1