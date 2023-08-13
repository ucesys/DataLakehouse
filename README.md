# What is this project about?

This repository is an extension to Alex's Merced blogpost regarding setting
up a Local Data Lakehouse using MinIO/Nessie/Spark/Dremio.   
https://dev.to/alexmercedcoder/data-engineering-create-a-apache-iceberg-based-data-lakehouse-on-your-laptop-41a8

Nessie catalog is supported as Dremio Data Source for Dremio >= 24.X, 
prior to that we have to use either Hive Metastore or Glue as Iceberg Catalog.
The goal of this repository is to create a setup with HMS as our Iceberg Catalog instead of Nessie.

# MinIO / Nessie / Spark / Dremio
### MinIO 

*1. Start minio*  
```buildoutcfg
docker-compose up minioserver
```
*2. Go to localhost:9001 and login minioadmin/minioadmin*  
*3. Create the very fist bucket warehouse-bucket*  
*4. Copy and paster access/secret key to .env.TEMPLATE file*  
*5. Rename .env.TEMPLATE to .env*

### Nessie
```buildoutcfg
docker-compose up nessie
```

### Spark with Nessie as Iceberg Catalog
*1. Start spark notebook*  
```buildoutcfg
docker-compose up notebook
```
*2. In the logs when this container open look for output the looks
 like the following and copy and paste the URL into your browser.*
 ```buildoutcfg
notebook  |  or http://127.0.0.1:8888/?token=9db2c8a4459b4aae3132dfabdf9bf4396393c608816743a9
```
*3. In the jupyter notebook go to spark_notebooks/spark_minio_nessie_iceberg*  
*4. Run the notebook*   
*5. Check if data exists in MinIO*

### Dremio
*1. Start dremio*
```buildoutcfg
docker-compose up dremio
```
*2. Go to localhost:9047 and create your admin account*  
*3. Go to Add Source -> Nessie*  
*4. Configure The following:*
- General->Nessie Endpoint URL: http://nessie:19120/api/v2
- General->Nessie Authentication Type: None
- Storage->Authentication Type: AWS Access Key
- Storage->AWS Access Key/Secret: Fill with generated MinIO access/secret
- Storage->AWS Root path: /warehouse
- Storage->Connection properties: Add the following
  - Name: fs.s3a.path.style.access, Value: true
  - Name: fs.s3a.endpoint, Value: minio:9000
  - Name: dremio.s3.compat, Value: true
- Storage->Encrypt connection: Turn off  

*5. Save Data source, you should be able to see and query the data*

