/*
====================================================================================
DDL SCRIPT: CREATE BRONZE TABLES
====================================================================================
SCRIPT PURPOSE:
 THIS SCRIPT CREATES TABLES IN THE 'BRONZE' SCHEMA, DROPPING EXISTING TABLES IF THEY
 ALREADY EXIST.
 RUN THIS SCRIPT TO DE-DEFINE THE DDL STRUCTURE OF BRONZE TABLES.
=====================================================================================
*/
IF OBJECT_ID ('bronze.crm_cust_info','U') IS NOT NULL
  DROP TABLE bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info(
cst_id INT,
cst_key NVARCHAR(50),
cst_firstname NVARCHAR(50),
cst_lastname NVARCHAR(50),
cst_material_status NVARCHAR(50),
cst_gndr NVARCHAR(50),
cst_create_date DATE
);

----------------------------------------------
IF OBJECT_ID('bronze.crm_prd_info','U') IS NOT NULL
   DROP TABLE bronze.crm_prd_info;
GO
CREATE TABLE bronze.crm_prd_info(
prd_id INT,
prd_key NVARCHAR(50),
prd_nm NVARCHAR(50),
prd_cost INT,
prd_line NVARCHAR(50),
prd_start_dt DATETIME,
prd_end_dt DATETIME
);

------------------------------------------------
IF OBJECT_ID ('bronze_crm_sales_details','U');
  DROP TABLE bronze_crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details(
sls_ord_num NVARCHAR(50),
sls_prd_key NVARCHAR(50),
sls_cust_id INT,
sls_order_dt INT,
sls_ship_dt INT,
sls_due_dt INT,
sls_sales INT,
sls_quantity INT,
sls_price INT
);

----------------------------------------------
IF OBJECT_ID ('bronze.erp_cust_az12','U');
  DROP TABLE bronze.erp_cust_az12;
GO
CREATE TABLE bronze.erp_cust_az12(
CID NVARCHAR(50),
BDATE DATE,
GEN NVARCHAR(50)
);

-----------------------------------------------
IF OBJECT_ID('bronze.erp_loc_a101','U');
  DROP TABLE bronze.erp_loc_a101;
GO

CREATE TABLE bronze.erp_loc_a101(
cid NVARCHAR(50),
cntry NVARCHAR(50)
);

------------------------------------------------
IF OBJECT_ID ('bronze.erp_px_cat_g1v2','U') IS NOT NULL
  DROP TABLE bronze.erp_px_cat_g1v2;
GO
CREATE TABLE bronze.erp_px_cat_g1v2(
ID NVARCHAR(50),
CAT NVARCHAR(50),
SUBCAT NVARCHAR(50),
MAINTENANCE NVARCHAR(50)
);
