{{ config(
    materialized='incremental',
    incremental_strategy='append'
) }}

WITH source_data AS (

    SELECT

        MD5_HEX(TRIM(CUSTOMER_ID)) AS CUSTOMER_HK,

        CUSTOMER_NAME,

        CUSTOMER_EMAIL,

        CUSTOMER_PHONE,

        MD5_HEX(
            CONCAT_WS(
                '||',
                COALESCE(CUSTOMER_NAME, '<NULL>'),
                COALESCE(CUSTOMER_EMAIL, '<NULL>'),
                COALESCE(CUSTOMER_PHONE, '<NULL>')
            )
        ) AS HASHDIFF,

        CURRENT_TIMESTAMP() AS LOAD_DTS,

        'RAW_CUSTOMERS' AS RECORD_SOURCE

    FROM {{ ref('stg_customers') }}

    WHERE CUSTOMER_ID IS NOT NULL

)

SELECT
    CUSTOMER_HK,
    CUSTOMER_NAME,
    CUSTOMER_EMAIL,
    CUSTOMER_PHONE,
    HASHDIFF,
    LOAD_DTS,
    RECORD_SOURCE

FROM source_data

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1
    FROM {{ this }} existing

    WHERE existing.CUSTOMER_HK = source_data.CUSTOMER_HK
      AND existing.HASHDIFF = source_data.HASHDIFF

)

{% endif %}