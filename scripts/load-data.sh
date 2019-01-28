#!/bin/bash
cassandra -R &> /dev/null &
mongod &> /dev/null &
echo "Hi, MongoDB and Cassandra are starting..."

# Preprocess data: take values from SQL dump into the sources
mvn clean install -f /usr/local/SANSA-DataLake_example/SQLtoNOSQL/pom.xml
echo "***************************Loading data to CSV***************************"
mvn exec:java -f /usr/local/SANSA-DataLake_example/SQLtoNOSQL/pom.xml -Dexec.args="/root/data/input/09Person.sql Person /root/input/config"

echo "***************************Loading data to Parquet***********************"
mvn exec:java -f /usr/local/SANSA-DataLake_example/SQLtoNOSQL/pom.xml -Dexec.args="/root/data/input/10Review.sql Review /root/input/config"

echo "***************************Preparing Cassandra DB************************"
cqlsh -e "CREATE KEYSPACE db WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '1'}  AND durable_writes = true;"
cqlsh -e 'CREATE TABLE db.product (nr int PRIMARY KEY, comment text,  label text, producer int, "propertyNum1" int, "propertyNum2" int, "propertyNum3" int, "propertyNum4" int, "propertyNum5" int, "propertyNum6" int, "propertyTex1" text, "propertyTex2" text, "propertyTex3" text, "propertyTex4" text, "propertyTex5" text, "propertyTex6" text, "publishDate" date, publisher int);'

echo "***************************Loading data to Cassandra*********************"
mvn exec:java -f /usr/local/SANSA-DataLake_example/SQLtoNOSQL/pom.xml -Dexec.args="/root/data/input/04Product.sql Product /root/input/config"

echo "***************************Loading data to MongoDB***********************"
mvn exec:java -f /usr/local/SANSA-DataLake_example/SQLtoNOSQL/pom.xml -Dexec.args="/root/data/input/08Offer.sql Offer /root/input/config"

# Start MySQL
# chown -R mysql:mysql /var/lib/mysql /var/run/mysqld
/etc/init.d/mysql start

cd  /root/data/input
mysql -u root --password=root mysql < 03Producer.sql

cd /usr/local/squerall-gui; sbt "run"; cd -
