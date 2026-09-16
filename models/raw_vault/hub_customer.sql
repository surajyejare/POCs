{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='customer_hk'
) }}

WITH source_data AS (

    SELECT DISTINCT
        CUSTOMER_ID,

        MD5_HEX(TRIM(CUSTOMER_ID)) AS CUSTOMER_HK,

        CURRENT_TIMESTAMP() AS LOAD_DTS,

        'RAW_CUSTOMERS' AS RECORD_SOURCE

    FROM {{ ref('stg_customers') }}

    WHERE CUSTOMER_ID IS NOT NULL

)

SELECT
    CUSTOMER_HK,
    CUSTOMER_ID,
    LOAD_DTS,
    RECORD_SOURCE

FROM source_data

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1
    FROM {{ this }} existing

    WHERE existing.CUSTOMER_HK = source_data.CUSTOMER_HK

)

{% endif %}