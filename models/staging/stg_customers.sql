WITH source_data AS (

    SELECT
        CAST(CUSTOMER_ID AS VARCHAR) AS CUSTOMER_ID,

        NULLIF(TRIM(CUSTOMER_NAME), '') AS CUSTOMER_NAME,

        LOWER(
            NULLIF(TRIM(CUSTOMER_EMAIL), '')
        ) AS CUSTOMER_EMAIL,

        NULLIF(TRIM(CUSTOMER_PHONE), '') AS CUSTOMER_PHONE

    FROM {{ source('raw', 'raw_customers') }}

)

SELECT *
FROM source_data