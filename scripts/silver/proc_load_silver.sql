/*
============================================================================================================
STORED PROCEDURE:LOAD SILVER LAYER (BRONZE-> SILVER)
============================================================================================================
SCRIPT PURPOSE:
    This stored procedure performs the ETL(EXTRACT,TRANSFORM,LOAD) Process to populate the 'silver' schema
    tables from the 'bronze' schema'

Actions Performed:
  -Truncates Silver tables.
  -Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
   None.
   This stored procedure does not accept any parameters or return any values.

Usage Example:
   Exec silver.load_silver;
==========================================================================================================
*/
CREATE OR ALTER PROCEDURE SILVER.LOAD_SILVER AS
BEGIN
    DECLARE @STARTTIME DATETIME,@ENDTIME DATETIME,@BATCH_START_TIME DATETIME,@BATCH_END_TIME DATETIME;
    BEGIN TRY
    SET @BATCH_START_TIME = GETDATE();
    PRINT('==============================================================');
    PRINT('LOADING SILVER LAYER');
    PRINT('==============================================================');

    PRINT('---------------------------------------------------------------');
    PRINT('LOADING CRM TABLES');
    PRINT('---------------------------------------------------------------');
    
    SET @STARTTIME=GETDATE();
    PRINT('>>TRUNCATING TABLE:SILVER.CRM_CUST_INFO');
    TRUNCATE TABLE SILVER.CRM_CUST_INFO;
    PRINT('>> INSERTING DATA INTO : SILVER.CRM_CUST_INFO');
    INSERT INTO SILVER.CRM_CUST_INFO(CST_ID,CST_KEY,CST_FIRSTNAME,CST_LASTNAME,CST_MATERIAL_STATUS,CST_GNDR,CST_CREATE_DATE)
    SELECT CST_ID,
           CST_KEY,
           UPPER(TRIM(CST_FIRSTNAME)) AS CST_FIRSTNAME,
           UPPER(TRIM(CST_LASTNAME)) AS CST_LASTNAME,
           CASE 
               WHEN UPPER(CST_MATERIAL_STATUS) = 'M' THEN 'MARRIED'
               WHEN UPPER(CST_MATERIAL_STATUS) = 'S' THEN 'SINGLE'
               ELSE 'N/A'
            END AS CST_MATERIAL_STATUS,
            CASE 
                WHEN UPPER(TRIM(CST_GNDR)) = 'F' THEN 'FEMALE'
                WHEN UPPER(TRIM(CST_GNDR)) = 'M' THEN 'MALE'
                ELSE 'N/A'
            END AS CST_GNDR,
            CST_CREATE_DATE
    FROM (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY CST_ID ORDER BY CST_CREATE_DATE DESC) AS RNKS
           FROM BRONZE.CRM_CUST_INFO
           WHERE CST_ID IS NOT NULL
     )T WHERE RNKS = 1;
     SET @ENDTIME=GETDATE();
     PRINT('>> LOAD DURATION:'+CAST(DATEDIFF(SECOND,@STARTTIME,@ENDTIME) AS NVARCHAR)+ 'SECONDS');
     PRINT('>>------------------------');

    --============================================================================================
    ----------------------------------------------------------------------------------------------
    --============================================================================================
    SET @STARTTIME=GETDATE();
    PRINT('>>TRUNCATING TABLE:SILVER.CRM_PRD_INFO');
    TRUNCATE TABLE SILVER.CRM_PRD_INFO;
    PRINT('>> INSERTING DATA INTO : SILVER.CRM_PRD_INFO');
    INSERT INTO SILVER.CRM_PRD_INFO(
    prd_id,
    cat_id,
    prd_key,
    prd_nm ,
    prd_cost,
    prd_line ,
    prd_start_dt,
    prd_end_dt
    )
     SELECT PRD_ID,
           REPLACE(SUBSTRING(PRD_KEY,1,5),'-','_') AS CAT_ID, --EXTRACT CATEGORY ID
           SUBSTRING(PRD_KEY,7,LEN(PRD_KEY))  AS PRD_KEY, --EXTARCT PRODUCT KEY
           PRD_NM,
           ISNULL(PRD_COST,0) AS PRD_COST,
           CASE
               WHEN UPPER(TRIM(PRD_LINE)) = 'M' THEN 'MOUNTAIN'
               WHEN UPPER(TRIM(PRD_LINE)) = 'R' THEN 'ROAD'
               WHEN UPPER(TRIM(PRD_LINE)) = 'S' THEN 'OTHER SALES'
               WHEN UPPER(TRIM(PRD_LINE)) = 'T' THEN 'TOURING'
               ELSE 'N/A'
            END AS PRD_LINE,
            CAST(PRD_START_DT AS DATE) AS PRD_START_DT,
            CAST(
                 LEAD(PRD_START_DT) OVER(PARTITION BY PRD_KEY ORDER BY PRD_START_DT) -1 AS DATE
                 ) AS PRD_END_DT --CALCULATE END DATE AS ONE DAY BEFORE THE NEXT START DATE
    FROM BRONZE.CRM_PRD_INFO;
    SET @ENDTIME=GETDATE();
    PRINT('>> LOAD DURATION:'+CAST(DATEDIFF(SECOND,@STARTTIME,@ENDTIME) AS NVARCHAR)+ 'SECONDS');
    PRINT('>>------------------------');

    --===================================================================================

    --SELECT * FROM bronze.crm_sales_details;
    SET @STARTTIME=GETDATE();
    PRINT('>>TRUNCATING TABLE:silver.crm_sales_details');
    TRUNCATE TABLE silver.crm_sales_details;
    PRINT('>> INSERTING DATA INTO : silver.crm_sales_details');
    INSERT INTO silver.crm_sales_details(
    sls_ord_num ,
    sls_prd_key,
    sls_cust_id ,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
    )
    SELECT SLS_ORD_NUM,
           SLS_PRD_KEY,
           SLS_CUST_ID,
           CASE WHEN SLS_ORDER_DT = 0 OR LEN(SLS_ORDER_DT)!=8 THEN NULL
                ELSE CAST(CAST(SLS_ORDER_DT AS NVARCHAR) AS DATE)
           END AS SLS_ORDER_DT,
           CASE WHEN SLS_SHIP_DT = 0 OR LEN(SLS_SHIP_DT)!=8 THEN NULL
                ELSE CAST(CAST(SLS_SHIP_DT AS NVARCHAR) AS DATE)
           END AS SLS_SHIP_DT,
           CASE WHEN SLS_DUE_DT = 0 OR LEN(SLS_DUE_DT) !=8 THEN NULL
                ELSE CAST(CAST(SLS_DUE_DT AS NVARCHAR) AS DATE)
           END AS SLS_DUE_DT,
           CASE WHEN SLS_SALES IS NULL OR SLS_SALES <=0 OR SLS_SALES !=SLS_QUANTITY*ABS(SLS_PRICE) THEN SLS_QUANTITY * ABS(SLS_PRICE)
                ELSE SLS_SALES
           END AS SLS_SALES,
           SLS_QUANTITY,
           CASE WHEN SLS_PRICE IS NULL OR SLS_PRICE<=0 THEN SLS_SALES / NULLIF(SLS_QUANTITY,0)
                ELSE SLS_PRICE 
           END AS SLS_PRICE
    FROM bronze.crm_sales_details;
    SET @ENDTIME=GETDATE();
     PRINT('>> LOAD DURATION:'+CAST(DATEDIFF(SECOND,@STARTTIME,@ENDTIME) AS NVARCHAR)+ 'SECONDS');
     PRINT('>>------------------------');
 
    --------------------------------------------------------------------------------------------
    --==========================================================================================
    -------------------------------------------------------------------------------------------- 
    SET @STARTTIME=GETDATE();
    PRINT('>>TRUNCATING TABLE:silver.erp_cust_az12');
    TRUNCATE TABLE silver.erp_cust_az12;
    PRINT('>> INSERTING DATA INTO : silver.erp_cust_az12');
    INSERT INTO silver.erp_cust_az12(
    CID,
    BDATE,
    GEN
    )
    SELECT 
    CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID,4,LEN(CID))
         ELSE CID
    END AS CID,
    CASE WHEN BDATE > GETDATE() THEN NULL
         ELSE BDATE
    END AS BDATE,
    CASE WHEN UPPER(TRIM(GEN)) IN ('MALE','M') THEN 'MALE'
         WHEN UPPER(TRIM(GEN)) IN ('FEMALE','F') THEN 'FEMALE'
         ELSE 'N/A'
    END AS GEN
    FROM bronze.erp_cust_az12;
    SET @ENDTIME=GETDATE();
     PRINT('>> LOAD DURATION:'+CAST(DATEDIFF(SECOND,@STARTTIME,@ENDTIME) AS NVARCHAR)+ 'SECONDS');
     PRINT('>>------------------------');

    ---------------------------------------------------------------------------
    --=========================================================================
    ---------------------------------------------------------------------------
    SET @STARTTIME=GETDATE();
    PRINT('>>TRUNCATING TABLE:silver.erp_loc_a101');
    TRUNCATE TABLE silver.erp_loc_a101;
    PRINT('>> INSERTING DATA INTO : silver.erp_loc_a101');
    INSERT INTO silver.erp_loc_a101(
    cid,cntry
    )

    SELECT REPLACE(CID,'-','') AS CID,
           CASE
               WHEN TRIM(CNTRY) IN ('US','USA') THEN 'UNITED STATES'
               WHEN TRIM(CNTRY) = 'DE' THEN 'GERMANY' 
               WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'N/A'
               ELSE TRIM(CNTRY)
            END AS CNTRY
    FROM bronze.erp_loc_a101;
    SET @ENDTIME=GETDATE();
     PRINT('>> LOAD DURATION:'+CAST(DATEDIFF(SECOND,@STARTTIME,@ENDTIME) AS NVARCHAR)+ 'SECONDS');
     PRINT('>>------------------------');

    -----------------------------------------------------------------------------
    --===========================================================================
    -----------------------------------------------------------------------------
    SET @STARTTIME=GETDATE();
    PRINT('>>TRUNCATING TABLE:SILVER.ERP_PX_CAT_G1V2');
    TRUNCATE TABLE SILVER.ERP_PX_CAT_G1V2;
    PRINT('>> INSERTING DATA INTO : SILVER.ERP_PX_CAT_G1V2');
    INSERT INTO SILVER.ERP_PX_CAT_G1V2(
    ID,CAT,SUBCAT,MAINTENANCE
    )
    SELECT ID,CAT,SUBCAT,MAINTENANCE FROM BRONZE.ERP_PX_CAT_G1V2;
    SET @ENDTIME=GETDATE();
    PRINT('>> LOAD DURATION:'+CAST(DATEDIFF(SECOND,@STARTTIME,@ENDTIME) AS NVARCHAR)+ 'SECONDS');
    PRINT('>>------------------------');
    SET @BATCH_END_TIME=GETDATE();
     PRINT('=======================================');
     PRINT('LOADING BRONZE LAYER IS COMPLETED');
     PRINT('TOTAL LOAD DURATION:'+CAST(DATEDIFF(SECOND,@BATCH_START_TIME,@BATCH_END_TIME) AS NVARCHAR)+'SECONDS');
     PRINT('========================================');
    END TRY
    BEGIN CATCH
    PRINT('ERROR OCCURED LOADING DURING SILVER LAYER');
    PRINT('ERROR MESSAGE:'+ERROR_MESSAGE());
    PRINT('ERROR MESSAGE:'+CAST(ERROR_NUMBER() AS NVARCHAR));
    END CATCH
END
