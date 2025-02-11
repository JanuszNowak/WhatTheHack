# Lab 1 -- Data Warehouse Migration

[Next Challenge>](../Challenge2/Readme.md)

## Story

WWI wants to modernize their data warehouse in phases.  The first stage will be to scale-out horizontally their existing data warehouse (SQL Server OLAP) to Azure Synapse Analytics.
They like to reuse their existing ETL code and leave their source systems as-is (no migration).  This will require a Hybrid architecture for on-premise OLTP and Azrue Synapse.  This exercise will
be showcasing how to migrate your traditional SQL Server (SMP) to Azure Synapse Analytics (MPP).

## Environment Setup

**Note:** The coach's notes and students guides will leverage the terms Azure Data Lake Store Gen2, Azure Data Factory and Azure Synapse Analytics.  These terms will be replaced with Linked Storage, Data Pipelines and SQL Pools respectively in future updates of the WTH.  It is acceptable to use Synapse Analytics Workspace as one of the adventures and use SQL Pools for the data warehouse.

WWI runs their existing database platforms on-premise with SQL Server 2017.  There are two databases samples for WWI.  The first one is for their Line of Business application (OLTP) and the second is for their data warehouse (OLAP).  You will need to setup both environments as our starting point in the migration.  Recommended to have students start Challenge 0 with setup of SQL environment before starting any presentations.

1. Open your browser and login to your Azure Tenant.  We plan to setup the Azure Services required for the What the Hack (WTH).  In your portal, open the [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview)

2. Go into the cloud shell and select the subscription you plan to use for this WTH.

```
az account set --subscription {"Subscription Name"}
az account show
```

3. Create a resource group to store the Modern Data Warehouse What the Hack.  This will be the services for your source systems/environments.  In Cloudshell, run this command

```
az group create --location eastus2 --name {"Resource Group Name"}
```

4. In the Cloudshell, run this command to create a SQL Server instance and restore the databases.  This will create an Azure Container Instance and restore the WideWorldImporters and WideWorldImoprtersDW databases.  These two databases are your LOB databases for this hack.

```
az container create -g {Resource Group Name} --name mdwhackdb --image alexk002/sqlserver2019_demo:1  --cpu 2 --memory 7 --ports 1433 --ip-address Public
```
**Note: In order to connect to this database server, the public IP address of the deployed container should be used as the hostname, and the default login credentials can be found in the [source repo for this container found on Docker Hub](https://hub.docker.com/repository/docker/alexk002/sqlserver2019_demo)

5. Review the database catalog on the data warehouse for familiarity of the schema [Reference document](https://docs.microsoft.com/en-us/sql/samples/wide-world-importers-dw-database-catalog?view=sql-server-ver15)

6. Review ETL workflow to understand the data flow and architecture [Reference document](https://docs.microsoft.com/en-us/sql/samples/wide-world-importers-perform-etl?view=sql-server-ver15)

7. Create an Azure Synapse Analytics Dedicated SQL Pool with the lowest DWU [Step by step guidance](https://docs.microsoft.com/en-us/azure/synapse-analytics/quickstart-create-sql-pool-studio) Recommended size of Azure Synapse is DW100.
    * Add your client IP address to the firewall for Synapse

## Tools

1. [SQL Server Management Studion (Version 18.x or higher)](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver15)
2. [Visual Studio Code](https://code.visualstudio.com/Download)
3. [Power BI Desktop](https://www.microsoft.com/en-us/download/details.aspx?id=58494)


## Migration Overview

The objective of this lab is to migrate the WWI DW (OLAP) to Azure Synapse Analytics.  Azure Synapse Analytics is a MPP (Massive Parallel Processing) platform that allows you to scale out your datawarehouse by adding new server nodes (compute) rather than adding more cores to the server.

Reference:
1. [Architecture Document of the MPP platform](https://docs.microsoft.com/en-us/azure/synapse-analytics/migration-guides/migrate-to-synapse-analytics-guide)
2. [SQL Server Database to Azure Synapse Analytics - Data Migration Guide](https://datamigration.microsoft.com/scenario/sql-to-sqldw?step=1)

There will be four different object types we'll migrate:

* Database Schema
* Database code (Store Procedure, Function, Triggers, etc)
* SSIS code set refactor (Share SSIS Job with team before they load data in Synapse)
* Data migration (with SSIS)

Guidelines will be provided below but you will have to determine how best to migrate.  At the end of the migration compare your
end state to the one we've published into the "Coach/Solutions/Challenge1" folder.  The detailed migration guide below is here for things to consider during your migration.

### Database Schema migration steps

Database schemas need to be migrated from SQL Server to Azure Synapse.  Due to the MPP architecture, this will be more than just a data type translation exericse.  You will need to focus on how best to distribute the data across each table follow this [document](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql/develop-tables-overview).  A list of unsupported data types can be found in this [article](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql/develop-tables-data-types#unsupported-data-types) and how to find the best alternative. For Geography fields, please advise students to drop them from the DDL statements since they will not be part of teh SSIS job.

1. Go to Source database on the SQL Server environment and right click the WWI DW database and select "Generate Scripts".  This will export all DDL statements for the database tables and schema.
2. Create a user defined schema for each tier of the data warehouse; Integration, Dimension, Fact.
3. Items that require refactoring (You can refer to this [document](https://docs.microsoft.com/en-us/sql/t-sql/statements/create-table-azure-sql-data-warehouse?view=azure-sqldw-latest) for more information)
    * Data types
    * Column length
    * Replace Identity for Sequences
    * Identify which tables are hash, replicated and round-robin. Read this [document](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-tables-distribute?context=%2Fazure%2Fsynapse-analytics%2Fcontext%2Fcontext)
    * Determine your distribution column (HINT IDENTITY Column can not be your distribution key)
    * Some Fact Table primary key are a composite key from source system
4. Execute these scripts on the Azure Synapse Analytics database
5. Run this query to identify which columns are not supported by Azure Synapse Analytics
```
SELECT  t.[name], c.[name], c.[system_type_id], c.[user_type_id], y.[is_user_defined], y.[name]
	FROM sys.tables  t
	JOIN sys.columns c on t.[object_id]    = c.[object_id]
	JOIN sys.types   y on c.[user_type_id] = y.[user_type_id]
	WHERE y.[name] IN ('geography','geometry','hierarchyid','image','text','ntext','sql_variant','timestamp','xml')
	OR  y.[is_user_defined] = 1;
```
6. Review IDENTITY article to ensure surrogate keys are in the right sequence [Reference document](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-tables-identity?context=%2Fazure%2Fsynapse-analytics%2Fcontext%2Fcontext)


### Database code rewrite

Review the SSIS jobs that are at this [Github repo](https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0) (Daily.ETL.ispac)  This job leverages stored procedures in the Source and Target databases extensively.  This will require a refactoring of the Stored procedures for the OLAP database when you repoint the ETL target to Azure Synapse.  There are a number of design considerations you wil need to consider when refactoring this code.  Please read this [document](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql/develop-tables-overview) for more detail.

There are three patterns you can reuse across all scripts in the same family (Dimension & Fact).

1. Rewrite Dimension T-SQL
    1. "Exec as Owner" and Return can be removed for this lab
2. Rewrite Fact T-SQL
    1. Movement T-SQL is a special fact table that leverages a MERGE Statement.  [Merge is not supported today](https://docs.microsoft.com/en-us/sql/t-sql/statements/merge-transact-sql?view=azure-sqldw-latest&preserve-view=true#remarks) in Azure Synapse.  Due to Identity column in Movement Table, Merge statement is not supported.  You will need to split it out into an Update and Insert statement.  [Merge Workaround](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-develop-ctas?context=%2Fazure%2Fsynapse-analytics%2Fcontext%2Fcontext#ansi-join-replacement-for-merge)
    1. "Exec as Owner" and RETURN can be removed for this lab

### SSIS Job Refactor -- Informational and not required as a success criteria for this hack
Data movement in first lab will be execution of DailyETLMDWLC.ispac job in Azure Data Factory SSIS Runtime.  This lab will reuse data pipelines to minimize migration costs. As data volumes increase, these jobs will need to leverage a MPP platform like Databricks, Synapse, HDInsight to transform the data at scale.  This will be done in a future lab.  These instructions are here to explain to you the steps performed to refactor the code set.  Only have student refactor if they have the time and expertise with SSIS.  This is not a learning objective of the Hack.

1. Open SSIS package and change Source and Destination database connections. Change the login from Windows Auth to SQL Auth
1. Update each mapping that required DDL changes. (City and Employee Tables)
1. Change Deployment properties to deploy package to SQL Server 2017.  This will enable it to be deployed to ADF SSIS Runtime directly.
1. Unit test the jobs in SSDT before deploying them to SSIS Runtime to ensure no errors
1. Refactoring SSIS jobs are not a success criteria in this hack.  Please provide them the ispac package from the library when they complete deploying the stored procedures.  Recommend the SSIS package to migrate the data and ask them to run it in ADF SSIS Runtime.

### Data Migration

There are numerous strategies and tools to migrate your data from on-premise to Azure [Reference document](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/design-elt-data-loading). We will leverage the SSIS packages to migrate our data from on-premise WWI DB to Azure Synapse Analytics.

1. Deploy SSIS package to SSIS Catalog following these instructions [Reference document].(https://docs.microsoft.com/en-us/sql/integration-services/lift-shift/ssis-azure-deploy-run-monitor-tutorial?view=sql-server-ver15#deploy-a-project-with-the-deployment-wizard)
1. Create ADF pipeline with Execute SSIS Package activity. [ADF Activity](https://docs.microsoft.com/en-us/azure/data-factory/how-to-invoke-ssis-package-ssis-activity?tabs=data-factory#create-a-pipeline-with-an-execute-ssis-package-activity)
1. Update [connection settings](https://docs.microsoft.com/en-us/azure/data-factory/how-to-invoke-ssis-package-ssis-activity?tabs=data-factory#connection-managers-tab) in package.
1. Execute this package to load data into Azure Synapse Analytics. [SSIS Execution](https://docs.microsoft.com/en-us/azure/data-factory/how-to-invoke-ssis-package-ssis-activity?tabs=data-factory#run-the-pipeline)
1. ADF SSIS Runtime is not supported in Azure Synapse Analytics Pipelines GA.


### Data Setup in Synapse
For the first time setup only, you will need to execute the "Master Create.sql" script to populate all control tables before you execute the SSIS job.  This is required and it is only done on the initial setup.  After this is complete, you can run the SSIS job.  For all subsequent runs after the initial setup, execute the Reseed ETL Stored Procedure only.  This stored procedure will rollback the database to it's original state.

A coach's suggestion is to have your team setup two enviroments for this challenge; Dev and Test.  This way they can hack all they want in their dev environment and not worry about impacting the work they've done to date.  After each challenge they can promote their dev code or restore the solution files into their test environment.  This way you can ensure after each challenge their environment won't regress and prevent them from going to the next challenge.

## Congratulations!!!
The migration is complete.  Run your SSIS jobs to load data from OLTP to OLAP data warehouse.  You might want to create a load control table to setup incremental loads.  This will validate you've completed all steps successfully.  Compare the results of the WWI OLAP database vs. the one you've migrated into Azure Synapse Analytics.