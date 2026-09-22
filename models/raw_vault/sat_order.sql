{{ config(
    materialized='incremental',
    incremental_strategy='append'
) }}

WITH source_data AS (

    SELECT

        MD5_HEX(TRIM(ORDER_ID)) AS ORDER_HK,

        ORDER_DATE,

        ORDER_AMOUNT,

        MD5_HEX(
            CONCAT_WS(
                '||',
                COALESCE(TO_VARCHAR(ORDER_DATE), '<NULL>'),
                COALESCE(TO_VARCHAR(ORDER_AMOUNT), '<NULL>')
            )
        ) AS HASHDIFF,

        CURRENT_TIMESTAMP() AS LOAD_DTS,

        'RAW_ORDERS' AS RECORD_SOURCE

    FROM {{ ref('stg_orders') }}

    WHERE ORDER_ID IS NOT NULL

)

SELECT
    ORDER_HK,
    ORDER_DATE,
    ORDER_AMOUNT,
    HASHDIFF,
    LOAD_DTS,
    RECORD_SOURCE

FROM source_data

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1
    FROM (
        SELECT ORDER_HK, HASHDIFF
        FROM {{ this }}
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY ORDER_HK ORDER BY LOAD_DTS DESC
        ) = 1
    ) latest
    WHERE latest.ORDER_HK = source_data.ORDER_HK
      AND latest.HASHDIFF = source_data.HASHDIFF

)

{% endif %}