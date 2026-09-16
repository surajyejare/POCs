# Data Vault dbt Project

## 1. Project Overview

This project implements a simplified **Data Vault 2.0 data model** using **dbt and Snowflake**.

The project demonstrates how raw customer and order data can be:

1. Loaded into Snowflake RAW schema.
2. Cleaned and standardized using dbt staging models.
3. Transformed into a Raw Data Vault consisting of Hubs, Links, and Satellites.
4. Validated using dbt built-in and custom data quality tests.
5. Documented and executed using dbt Cloud.

### Technology Stack

* Snowflake
* dbt Cloud
* SQL
* Data Vault 2.0
* Git / GitLab

---

## 2. Snowflake Structure

The project uses the following Snowflake objects:

```text
DBT_PROJECT_DB
│
├── RAW
│   ├── RAW_CUSTOMERS
│   └── RAW_ORDERS
│
├── STAGING
│   ├── STG_CUSTOMERS
│   └── STG_ORDERS
│
└── RAW_VAULT
    ├── HUB_CUSTOMER
    ├── HUB_ORDER
    ├── LINK_CUSTOMER_ORDER
    ├── SAT_CUSTOMER
    └── SAT_ORDER
```

The Snowflake warehouse used by the project is:

```text
DBT_PROJECT_WH
```

---

## 3. Project Structure

```text
data_vault_dbt_project/
│
├── dbt_project.yml
├── README.md
│
├── models/
│   │
│   ├── staging/
│   │   ├── sources.yml
│   │   ├── staging.yml
│   │   ├── stg_customers.sql
│   │   └── stg_orders.sql
│   │
│   └── raw_vault/
│       ├── raw_vault.yml
│       ├── hub_customer.sql
│       ├── hub_order.sql
│       ├── link_customer_order.sql
│       ├── sat_customer.sql
│       └── sat_order.sql
│
└── tests/
    ├── test_duplicate_customer_satellite.sql
    └── test_duplicate_order_satellite.sql
```

---

## 4. Source Data

The source data is stored in the Snowflake `RAW` schema.

### RAW_CUSTOMERS

| Column         | Description                |
| -------------- | -------------------------- |
| CUSTOMER_ID    | Unique customer identifier |
| CUSTOMER_NAME  | Customer name              |
| CUSTOMER_EMAIL | Customer email             |
| CUSTOMER_PHONE | Customer phone number      |

### RAW_ORDERS

| Column       | Description                        |
| ------------ | ---------------------------------- |
| ORDER_ID     | Unique order identifier            |
| CUSTOMER_ID  | Customer associated with the order |
| ORDER_DATE   | Date of the order                  |
| ORDER_AMOUNT | Order amount                       |

Raw tables are defined centrally in:

```text
models/staging/sources.yml
```

The staging models reference these tables using dbt's `source()` function.

Example:

```sql
FROM {{ source('raw_data', 'raw_customers') }}
```

---

## 5. Staging Layer

The staging layer prepares the raw source data for the Data Vault.

### stg_customers

The customer staging model:

* Trims string values.
* Standardizes customer email to lowercase.
* Provides a clean structure for downstream models.

### stg_orders

The order staging model:

* Trims identifiers.
* Converts `ORDER_DATE` to DATE.
* Converts `ORDER_AMOUNT` to `NUMBER(18,2)`.
* Provides standardized order data.

Staging models are referenced by downstream models using:

```sql
{{ ref('stg_customers') }}
```

and:

```sql
{{ ref('stg_orders') }}
```

---

## 6. Raw Data Vault Layer

The Raw Vault contains Hubs, Links, and Satellites.

### HUB_CUSTOMER

Stores the unique business key for customers.

Main attributes:

* `CUSTOMER_HK`
* `CUSTOMER_ID`
* `LOAD_DTS`
* `RECORD_SOURCE`

The customer hash key is generated deterministically from `CUSTOMER_ID`.

---

### HUB_ORDER

Stores the unique business key for orders.

Main attributes:

* `ORDER_HK`
* `ORDER_ID`
* `LOAD_DTS`
* `RECORD_SOURCE`

The order hash key is generated deterministically from `ORDER_ID`.

---

### LINK_CUSTOMER_ORDER

The Link represents the relationship between a customer and an order.

Main attributes:

* `CUSTOMER_ORDER_HK`
* `CUSTOMER_HK`
* `ORDER_HK`
* `LOAD_DTS`
* `RECORD_SOURCE`

The Link uses a deterministic hash key based on the combination of customer and order identifiers.

---

### SAT_CUSTOMER

The Customer Satellite stores descriptive customer attributes and their historical changes.

Main attributes:

* `CUSTOMER_HK`
* `CUSTOMER_NAME`
* `CUSTOMER_EMAIL`
* `CUSTOMER_PHONE`
* `HASHDIFF`
* `LOAD_DTS`
* `RECORD_SOURCE`

`HASHDIFF` is used to identify changes in descriptive customer attributes.

---

### SAT_ORDER

The Order Satellite stores descriptive order information.

Main attributes:

* `ORDER_HK`
* `ORDER_DATE`
* `ORDER_AMOUNT`
* `HASHDIFF`
* `LOAD_DTS`
* `RECORD_SOURCE`

The Satellite allows changes to order attributes to be retained historically.

---

## 7. Data Vault Flow

The overall data flow is:

```text
Snowflake RAW
     │
     │ source()
     ▼
STAGING
     │
     │ ref()
     ▼
HUB_CUSTOMER ─────────┐
                      │
HUB_ORDER ────────────┤
                      ▼
              LINK_CUSTOMER_ORDER
                      │
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
   SAT_CUSTOMER              SAT_ORDER
```

The `source()` function is used to reference external/raw Snowflake tables.

The `ref()` function is used to create dependencies between dbt models.

---

## 8. Data Quality Tests

The project uses dbt built-in tests.

Examples include:

* `not_null`
* `unique`
* `relationships`

Tests are defined in:

```text
models/staging/staging.yml
models/raw_vault/raw_vault.yml
```

Custom singular tests are stored in:

```text
tests/
```

These tests validate that duplicate satellite records are not created for the same hash key and hashdiff combination.

---

## 9. Running the Project

### Step 1: Validate the dbt Connection

Run:

```bash
dbt debug
```

This verifies the dbt project and Snowflake connection.

---

### Step 2: Run Staging Models

```bash
dbt run --select staging
```

This creates the staging models in the configured staging schema.

---

### Step 3: Run Raw Vault Models

```bash
dbt run --select raw_vault
```

This creates the Hubs, Link, and Satellites.

---

### Step 4: Run All Models

```bash
dbt run
```

This executes the complete model pipeline.

---

### Step 5: Run Tests

```bash
dbt test
```

This executes the configured data quality tests.

---

### Step 6: Build Models and Tests

The recommended command for the complete pipeline is:

```bash
dbt build
```

`dbt build` runs the models and associated tests according to their dependency order.

---

## 10. Incremental Processing

The Raw Vault models are configured as incremental models.

This allows the pipeline to process new records without rebuilding the complete target tables on every execution.

For example, a new order can be inserted into the raw source:

```sql
INSERT INTO DBT_PROJECT_DB.RAW.RAW_ORDERS
VALUES
('103', '1', '2023-01-03', 200.00);
```

Then run:

```bash
dbt build
```

The new order should be processed into the appropriate Hub, Link, and Satellite structures.

---

## 11. Testing Historical Changes

To demonstrate Satellite historization, an existing order can be changed:

```sql
UPDATE DBT_PROJECT_DB.RAW.RAW_ORDERS
SET ORDER_AMOUNT = 125.00
WHERE ORDER_ID = '101';
```

Then execute:

```bash
dbt build
```

The Satellite model should retain the previous version and create a new version when the descriptive attributes change.

The `HASHDIFF` helps identify the change.

---

## 12. Documentation

Generate dbt documentation using:

```bash
dbt docs generate
```

The generated documentation provides information about:

* Models
* Columns
* Tests
* Sources
* Model dependencies
* Lineage

The lineage should demonstrate the flow from the raw source tables through staging and into the Raw Vault.

---

## 13. Useful Commands

| Command                      | Purpose                                             |
| ---------------------------- | --------------------------------------------------- |
| `dbt debug`                  | Validate dbt/Snowflake connection                   |
| `dbt run`                    | Run all models                                      |
| `dbt run --select staging`   | Run staging models                                  |
| `dbt run --select raw_vault` | Run Raw Vault models                                |
| `dbt test`                   | Run data quality tests                              |
| `dbt build`                  | Run models and tests                                |
| `dbt docs generate`          | Generate documentation                              |
| `dbt source freshness`       | Check source freshness when freshness is configured |

---

## 14. Expected Output

After a successful build, the Raw Vault schema should contain:

```text
DBT_PROJECT_DB.RAW_VAULT
│
├── HUB_CUSTOMER
├── HUB_ORDER
├── LINK_CUSTOMER_ORDER
├── SAT_CUSTOMER
└── SAT_ORDER
```

The project should complete successfully with all configured data quality tests passing.

---

## 15. Key Design Principles

This implementation follows the following Data Vault principles:

* Business keys are stored in Hubs.
* Relationships between business keys are stored in Links.
* Descriptive attributes are stored in Satellites.
* Hash keys provide deterministic identifiers.
* Hashdiffs help identify changes in Satellite attributes.
* `LOAD_DTS` records the load timestamp.
* `RECORD_SOURCE` identifies the originating source.
* dbt `source()` is used for raw source tables.
* dbt `ref()` is used for dependencies between dbt models.
* Incremental processing is used for the Raw Vault layer.
* dbt tests are used to validate data quality.

---

## 16. Project Execution Flow

```text
1. Load raw data into Snowflake
              ↓
2. Validate source definitions
              ↓
3. Run staging models
              ↓
4. Run Hub models
              ↓
5. Run Link model
              ↓
6. Run Satellite models
              ↓
7. Execute dbt tests
              ↓
8. Generate dbt documentation
              ↓
9. Review lineage and execution logs
```

This README provides the project setup, architecture, model descriptions, testing approach, incremental processing approach, and execution instructions required to understand and run the dbt Data Vault implementation.
