WITH source_data AS (

    SELECT
        CAST(ORDER_ID AS VARCHAR) AS ORDER_ID,

        CAST(CUSTOMER_ID AS VARCHAR) AS CUSTOMER_ID,

        CAST(ORDER_DATE AS DATE) AS ORDER_DATE,

        CAST(ORDER_AMOUNT AS NUMBER(18,2)) AS ORDER_AMOUNT

    FROM  {{ source('raw', 'raw_orders') }}

)

SELECT *
FROM source_data