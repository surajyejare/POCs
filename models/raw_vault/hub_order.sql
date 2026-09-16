{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='order_hk'
) }}

WITH source_data AS (

    SELECT DISTINCT
        ORDER_ID,

        MD5_HEX(TRIM(ORDER_ID)) AS ORDER_HK,

        CURRENT_TIMESTAMP() AS LOAD_DTS,

        'RAW_ORDERS' AS RECORD_SOURCE

    FROM {{ ref('stg_orders') }}

    WHERE ORDER_ID IS NOT NULL

)

SELECT
    ORDER_HK,
    ORDER_ID,
    LOAD_DTS,
    RECORD_SOURCE

FROM source_data

{% if is_incremental() %}

WHERE NOT EXISTS (

    SELECT 1
    FROM {{ this }} existing

    WHERE existing.ORDER_HK = source_data.ORDER_HK

)

{% endif %}