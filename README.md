# What is this project about?
The goal of this project is to create a local Iceberg Data Lakehouse consisting of the following components:
- MinIO as storage layer for storing tables in Iceberg Format
- Iceberg Catalog for storing latest metadata pointers per table
  - Option A: Hive Metastore
  - Option B: Nessie(Available as Dremio source since version 24.X)
- Spark & Dremio for interacting with Iceberg Tables 

<img src="https://github.com/ucesys/DataLakehouse/blob/main/assets/diagram.png" width="650"></img>  

Alex's Merced in his  [Data Engineering: Create a Apache Iceberg based Data Lakehouse on your Laptop](https://dev.to/alexmercedcoder/data-engineering-create-a-apache-iceberg-based-data-lakehouse-on-your-laptop-41a8) blogpost has created a local Data Lakehouse on MinIO using project Nessie. Nessie catalog is supported as Dremio Data Source since Dremio 24.X version. 
For Dremio versions <= 23.X, we are left with Hadoop, Glue and Hive Metastore options for Iceberg Catalog.
Due to concurrency problems with Hadoop Catalog, for <= 23.X non-aws Dremio installations, Hive Metastore remains the only choice for Iceberg Catalog.

# Step 0: Launch MinIO
### MinIO
*1. Start minio*  
```buildoutcfg
sudo docker-compose up minioserver
```
*2. Go to http://localhost:9001 and login using minioadmin/minioadmin credentials*  
*3. In the UI, go to Access keys -> Create new key, generate new credentials and download them, we will be using them later on.*  

# Architecture A: Dremio 23.1 with HMS as Iceberg Catalog
### Hive Metastore
*1. Download hadoop & aws dependencies for hive metastore, we will be mounting them later on as volumes*  
You can either use the following script:
```buildoutcfg
scripts/download-jars.sh
```
or download the following jars manually and place them in lib directory:
- [org.apache.hadoop:hadoop-common:3.3.2](https://mvnrepository.com/artifact/org.apache.hadoop/hadoop-common/3.3.2)
- [org.apache.hadoop:hadoop-aws:3.3.2](https://mvnrepository.com/artifact/org.apache.hadoop/hadoop-aws/3.3.2)
- [org.apache.hadoop:hadoop-auth:3.3.2](https://mvnrepository.com/artifact/org.apache.hadoop/hadoop-auth/3.3.2)
- [org.apache.hadoop.thirdparty:hadoop-shaded-guava:1.1.1](https://mvnrepository.com/artifact/org.apache.hadoop.thirdparty/hadoop-shaded-guava/1.1.1)
- [com.amazonaws:aws-java-sdk-bundle:1.11.1026](https://mvnrepository.com/artifact/com.amazonaws/aws-java-sdk-bundle/1.11.1026)

*2. Go to MinIO and create a bucket for our Iceberg Tables called "warehouse-hms"*  
*\*HMS doesn't allow top-level bucket directory to serve as warehouse dir, 
that's why our warehouse dir will be warehouse-bucket/warehouse*   

*3. Open conf/hive-site.xml and edit the following properties:* 
```buildoutcfg
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>s3a://<BUCKET-NAME>/warehouse</value>
    <description>For HMS warehouse dir cannot be top level bucket directory</description>
  </property>

  <property>
    <name>fs.s3a.access.key</name>
    <value><MinIO ACCESS KEY></value>
    <description></description>
  </property>

  <property>
    <name>fs.s3a.secret.key</name>
    <value><MinIO SECRET KEY></value>
    <description></description>
  </property>
```


*4. Start Hive Metastore in a new terminal window*
```buildoutcfg
sudo docker-compose up hivemetastore
```

### Connect Spark to Hive Metastore Iceberg Catalog
*1. Start spark notebook in a new terminal window*  
```buildoutcfg
sudo docker-compose up spark_notebook_hms
```
*2. Go to http://127.0.0.1:8888/lab/tree/spark_hms.ipynb*  
*3. Run the notebook & play with Iceberg tables*  
*4. Check if data & metadata exists in MinIO*

*\*In order to run spark in spark-shell or spark-sql, exec into spark container:*
```buildoutcfg
sudo docker exec -it spark_notebook_hms bash
```

and run spark-shell session with HMS as Iceberg Catalog*
```buildoutcfg
spark-shell \
--conf spark.sql.catalog.type=hive \
--conf spark.sql.catalog.spark_catalog=org.apache.iceberg.spark.SparkCatalog \
--conf spark.sql.catalog.iceberg_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO \
--conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions \
--conf spark.jars.packages=com.amazonaws:aws-java-sdk-bundle:1.11.1026,org.apache.hadoop:hadoop-aws:3.3.2,org.apache.iceberg:iceberg-spark-runtime-3.3_2.12:1.3.1,org.apache.iceberg:iceberg-spark3-extensions:0.13.1
```

### Connect Dremio 23.1 to Hive Metastore Iceberg Catalog 
*1. Start dremio in a new terminal window*
```buildoutcfg
sudo docker-compose up dremio23
```
*2. Go to http://localhost:9047 and create your admin account*  
*3. From UI Select Add Source -> Metastores -> Hive 3.x and configure the following properties:*   
<img src="https://github.com/ucesys/DataLakehouse/blob/main/assets/dremio-hms-minio-config-1.png" width="800"></img>  
<img src="https://github.com/ucesys/DataLakehouse/blob/main/assets/dremio-hms-minio-config-2.png" width="800"></img>  


# Architecture B: Dremio 24.1 with Nessie as Iceberg Catalog
### Nessie
*Start Nessie in a new terminal window*
```buildoutcfg
sudo docker-compose up nessie
```
### Connect Spark to Nessie Iceberg Catalog
*0. Go to MinIO and create a bucket for our Iceberg Tables called "warehouse-nessie"*  
*1. Use access & secret keys from credentials.json 
to fill AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY values in .env file*
```buildoutcfg
AWS_ACCESS_KEY_ID=<MinIO ACCESS KEY>
AWS_SECRET_ACCESS_KEY=<MinIO SECRET KEY>
WAREHOUSE_NESSIE=s3a://<NESSIE WAREHOUSE BUCKET>/
```
*2. Start spark notebook in a new terminal window*  
```buildoutcfg
sudo docker-compose up spark_notebook_nessie
```
*2. Go to http://127.0.0.1:8889/lab/tree/spark_nessie.ipynb*  
*3. Run the notebook & play with Iceberg tables*  
*4. Check if data & metadata exists in MinIO*

### Connect Dremio 24.1 to Nessie Iceberg Catalog
*1. Start dremio in a new terminal window*
```buildoutcfg
sudo docker-compose up dremio24
```
*2. Go to http://localhost:9048 and create your admin account*  
*3. Go to Add Source -> Nessie and configure The following:*  
<img src="https://github.com/ucesys/DataLakehouse/blob/main/assets/dremio-nessie-minio-config-1.png" width="800"></img>  
<img src="https://github.com/ucesys/DataLakehouse/blob/main/assets/dremio-nessie-minio-config-2.png" width="800"></img>  
*4. Save Data source, you should be able to see and query the data*


# FAQ

**Error**: *java.lang.RuntimeException: Failed to create namespace demo_hms in Hive Metastore. Caused by: MetaException(message:Got exception: java.nio.file.AccessDeniedException s3a://warehouse-hms/warehouse/demo_hms.db: getFileStatus on s3a://warehouse-hms/warehouse/demo_hms.db: com.amazonaws.services.s3.model.AmazonS3Exception: Forbidden (Service: Amazon S3; Status Code: 403; Error Code: 403 Forbidden*  
**Reason:** Hive Metastore cannot access MinIO bucket, probably hive-site.xml is misconfigured or access keys were not created in MinIO    
**Solution:** Check the following properties in hive-site.xml: fs.s3a.secret.key, fs.s3a.access.key, hive.metastore.warehouse.dir  
**Note:** Changing hive-site.xml requires restarting Hive Metastore and Spark  
 
 ---  
  
**Error**: *Schema initialization failed!* when starting Hive Metastore container   
**Reason:** Hive Metastore cannot initialize underlying database because it was already initialized   
**Solution:** Remove existing metastore container and start a new one
```buildoutcfg
sudo docker-compose rm hivemetastore
sudo docker-compose up hivemetastore
```
 ---  
