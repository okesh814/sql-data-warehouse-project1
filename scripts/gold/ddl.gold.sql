/*
=================================================================================================================
DDL SCRIPT:Create Gold Views
=================================================================================================================
Script Purpose:
      This script creates views for the Gold layer in the data warehouse.
      The gold layer represents the final dimension and fact tables(Star schema)

      Each view performs tarnsformation and data from the silver layer to product
      a clean, enriched, and business-redy dataset.
Usage:
      -These views can be queried directly for Analytics and reporting.
================================================================================================================
*/

--==============================================================================================================
--Create Dimension: gold.dim_customers
--==============================================================================================================
  IF OBJECT_ID('gold.dim_customers','V') IS NOT NULL
   DROP VIEW gold.dim_customers;
GO
   
CREATE VIEW gold.dim_customers AS
SELECT 
      ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key,
      ci.cst_id AS customer_id,
      ci.cst_key AS customer_number,
      ci.cst_firstname AS firstname,
      ci.cst_lastname AS lastname,
      la.cntry AS country,
      ci.cst_material_status marital_status,
      CASE WHEN ci.cst_gndr!='n/a' THEN ci.cst_gndr
           ELSE COALESCE(ca.gen,'n/a')
      END AS gender,
      ca.bday AS birthdate,
      ci.cst_create_date AS create_date
      FROM silver.crm_cust_info ci
      LEFT JOIN silver.erp_cust_az12 ca
      ON ci.cst_key=ca.cid
      LEFT JOIN silver.erp_loc_a101 la
      ON ci.cst_key=la.cid;
GO

-----------------------------------------------------------------------------------------------
--BUILDING GOLD LAYER
--CREATING DIMENSION PRODUCTS
--============================================================================================================
--BUILDING VIEW gold.dim_products
--============================================================================================================
IF OBJECT_ID('gold.dim_products','V') IS NOT NULL
   DROP VIEW gold.dim_products;
GO
CREATE VIEW gold.dim_products AS
SELECT 
      ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt,pn.prd_key) AS product_key,
      pn.prd_id AS product_id,
      pn.prd_key AS product_number,
      pn.prd_nm AS product_name,
      pn.cat_id AS category_id,
      pc.cat AS category,
      pc.subcat AS subcategory,
      pc.maintenance,
      pn.prd_cost AS cost,
      pn.prd_line AS product_line,
      pn.prd_start_dt AS start_date
      FROM silver.crm_prd_info pn
      LEFT JOIN silver.erp_px_cat_g1v2 pc
      ON pn.cat_id=pc.id

GO

---------------------------------------------------------------------------------------------
--BUILDING GOLD LAYER
--CREATING FACTS TABLE
--===========================================================================================
--BUILDING VIEW gold.fact_sales
--===========================================================================================
IF OBJECT_ID('gold.fact_sales','V') IS NOT NULL
   DROP VIEW gold.fact_sales;
   
GO

CREATE VIEW gold.fact_sales AS
SELECT
      sls_ord_num AS order_number,
      pr.product_key,
      cu.customer_key,
      sls_order_dt AS order_date,
      sls_ship_dt AS shipping_date,
      sls_due_dt AS due_date,
      sls_sales,
      sls_quantity,
      sls_price
      FROM silver.crm_sales_details AS sd
      LEFT JOIN gold.dim_products as pr
      ON sd.sls_prd_key=pr.product_number
      LEFT JOIN gold.dim_customers cu
      ON sd.sls_cust_id=cu.customer_id;
 
