{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='customer_order_hk'
) }}

WITH source_data AS (

    SELECT DISTINCT

        MD5_HEX(
            CONCAT(
                TRIM(o.CUSTOMER_ID),
                '||',
                TRIM(o.ORDER_ID)
            )
        ) AS CUSTOMER_ORDER_HK,

        MD5_HEX(TRIM(o.CUSTOMER_ID)) AS CUSTOMER_HK,

        MD5_HEX(TRIM(o.ORDER_ID)) AS ORDER_HK,

        CURRENT_TIMESTAMP() AS LOAD_DTS,

        'RAW_ORDERS' AS RECORD_SOURCE

    FROM {{ ref('stg_orders') }} o

    INNER JOIN {{ ref('hub_customer') }} c
        ON MD5_HEX(TRIM(o.CUSTOMER_ID)) = c.CUSTOMER_HK

    INNER JOIN {{ ref('hub_order') }} h
        ON MD5_HEX(TRIM(o.ORDER_ID)) = h.ORDER_HK

    WHERE o.CUSTOMER_ID IS NOT NULL
      AND o.ORDER_ID IS NOT NULL

)

SELECT
    CUSTOMER_ORDER_HK,
    CUSTOMER_HK,
    ORDER_HK,
    LOAD_DTS,
    RECORD_SOURCE

FROM source_data

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1
    FROM {{ this }} existing

    WHERE existing.CUSTOMER_ORDER_HK =
          source_data.CUSTOMER_ORDER_HK

)

{% endif %}