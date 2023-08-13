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

# Step 0: Launch MinIO and Dremio
### MinIO
*1. Start minio*  
```buildoutcfg
docker-compose up minioserver
```
*2. Go to localhost:9001 and login minioadmin/minioadmin*  
*3. Create the very fist bucket called "warehouse-bucket"*  
*\*HMS doesn't allow top-level bucket directory to serve as warehouse dir, 
that's why our warehouse dir will be warehouse-bucket/warehouse*   
*4. Copy and paste access/secret key to .env.TEMPLATE file*  
*5. Rename .env.TEMPLATE to .env*

### Dremio
*1. Start dremio in new terminal window*
```buildoutcfg
docker-compose up dremio
```
*2. Go to localhost:9047 and create your admin account*  


# Architecture A: HMS as Iceberg Catalog
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

*2. Start Hive Metastore in new terminal window*
```buildoutcfg
docker-compose up hivemetastore
```

### Connect Spark to Hive Metastore Iceberg Catalog 
*1. Exec into spark container*
```buildoutcfg
sudo docker exec -it notebook bash
```

*2. Run spark-shell session with HMS as Iceberg Catalog*
```buildoutcfg
spark-shell \
--conf spark.sql.catalog.type=hive \
--conf spark.sql.catalog.spark_catalog=org.apache.iceberg.spark.SparkCatalog \
--conf spark.sql.catalog.iceberg_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO \
--conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions \
--conf spark.jars.packages=com.amazonaws:aws-java-sdk-bundle:1.11.1026,org.apache.hadoop:hadoop-aws:3.3.2,org.apache.iceberg:iceberg-spark-runtime-3.3_2.12:1.3.1,org.apache.iceberg:iceberg-spark3-extensions:0.13.1
```

*\*To Run spark-shell with HMS(non-iceberg tables)*
```buildoutcfg
spark-shell --conf spark.jars.packages=com.amazonaws:aws-java-sdk-bundle:1.11.1026,org.apache.hadoop:hadoop-aws:3.3.2 
```

### Connect Dremio to Hive Metastore Iceberg Catalog 
*1. From UI Select Add Source -> Metastores -> Hive 3.x*   
*2. Configure Hive Metastore host, go to Advanced options and specify the following properties:*  
<img src="https://github.com/ucesys/DataLakehouse/blob/main/assets/dremio-hms-minio-config.png" width="800"></img>  


# Architecture B: Nessie as Iceberg Catalog (Dremio >= 24.x)
### Nessie
*Start Nessie in new terminal window*
```buildoutcfg
docker-compose up nessie
```
### Connect Spark to Nessie Iceberg Catalog
*1. Start spark notebook in new terminal window*  
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

### Connect Dremio to Nessie Iceberg Catalog
*1. Go to Add Source -> Nessie and configure The following:*  
<img src="https://github.com/ucesys/DataLakehouse/blob/main/assets/dremio-nessie-minio-config-1.png" width="800"></img>  
<img src="https://github.com/ucesys/DataLakehouse/blob/main/assets/dremio-nessie-minio-config-2.png" width="800"></img>  
*2. Save Data source, you should be able to see and query the data*
