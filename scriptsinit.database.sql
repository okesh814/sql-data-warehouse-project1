/*
=====================================================================================================
Create Database and schemas
=====================================================================================================
Script Purpose:
This script creates a new database named 'Datawarehouse' after checking if it already exists.
If the database exists, it is dropped and recreated . Additionally , the script sets up three schemas within 
the database: 'bronze', 'silver', and 'gold'.

Warning:
Running this script will drop the entire 'Datawarehouse' database if it exist.
All data in the database will be permanently deleted. proceed with caution and ensure you have proper backups before running this script.
*/

USE master;
GO

--Drop and recreate the 'Datawarehouse' database
IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME='Datawarehouse')
BEGIN
   ALTER DATABASE Datawarehouse SET SINGLE USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Datawarehouse;
END;
GO

--CREATE THE 'Datawarehouse' database
CREATE DATABASE Datawarehouse
GO

--CRETAE SCHEMAS
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
