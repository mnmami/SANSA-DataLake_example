FROM ubuntu:16.04

MAINTAINER Mohamed Nadjib Mami <mami@cs.uni-bonn.de>

# Install Utilities
RUN set -x && \
    apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends curl vim openjdk-8-jdk-headless apt-transport-https maven git wget unzip time && \
    # install SBT
    echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 && \
    apt-get update && \
    apt-get install -y sbt && \
    # cleanup
    apt-get clean

# Install MongoDB
RUN set -x && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5 && \
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.6.list && \
    apt-get update && \
    apt-get install -y mongodb-org && \
    mkdir -p /data/db

# Install Cassandra
RUN set -x && \
    echo "deb http://www.apache.org/dist/cassandra/debian 311x main" | tee -a /etc/apt/sources.list.d/cassandra.sources.list && \
    curl https://www.apache.org/dist/cassandra/KEYS | apt-key add - && \
    apt-get update && \
    apt-key adv --keyserver pool.sks-keyservers.net --recv-key A278B781FE4B2BDA && \
    apt-get -y install cassandra

# Install MySQL
RUN set -x && \
    echo 'mysql-server mysql-server/root_password password root' | debconf-set-selections  && \
    echo 'mysql-server mysql-server/root_password_again password root' | debconf-set-selections && \
    apt-get update && \
    apt-get install -y --no-install-recommends vim && \
    apt-get -y install mysql-server
    # to solve "Can't open and lock privilege tables: Table storage engine for 'user' doesn't have this option"
    # sed -i -e "s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf && \
    # /etc/init.d/mysql start

ENV SPARK_VERSION 2.4.0
ENV JENA_VERSION 3.9.0

# Install Spark
RUN set -x  && \
    curl -fSL -o - http://ftp-stud.hs-esslingen.de/pub/Mirrors/ftp.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz | tar xz -C /usr/local && \
    mv /usr/local/spark-${SPARK_VERSION}-bin-hadoop2.7 /usr/local/spark

# Generat test data
RUN set -x && \
    apt-get update --fix-missing && \
    apt-get install -y unzip

RUN set -x && \
    wget -O bsbm.zip https://sourceforge.net/projects/bsbmtools/files/latest/download && \
    unzip bsbm.zip && \
    rm bsbm.zip && \
    cd bsbmtools-0.2 && \
    ./generate -fc -pc 1000 -s sql -fn /root/data/input && \
    cd /root/data/input && \
    rm 01* 02* 05* 06* 07*

RUN apt-get update

# Get SANSA-DataLake
RUN set -x && \
    cd /usr/local && \
    git clone https://github.com/mnmami/SANSA-DataLake_example.git && \
    cd SANSA-DataLake_example && \
    mkdir /root/input /root/scripts && \
    cp -r /usr/local/SANSA-DataLake_example/input_files/* /root/input && \
    cp scripts/* /root/scripts && \
    mvn package

# Get Squerall GUIs
RUN set -x && \
    # Install Squerall-GUI
    git clone https://github.com/EIS-Bonn/squerall-gui.git && \
    mv squerall-gui /usr/local && \
    wget http://central.maven.org/maven2/org/apache/parquet/parquet-tools/1.8.0/parquet-tools-1.8.0.jar && \
    mv parquet-tools-1.8.0.jar /usr/local/lib

EXPOSE 9000

# Run welcome script
# RUN "bash /root/scripts/load-data.sh"

RUN ["chmod", "+x", "/root/scripts/load-data.sh"]

RUN pwd

# RUN "/root/scripts/load-data.sh"

CMD /root/scripts/load-data.sh

#RUN [“chmod”, “+x”, "/root/welcome-script.sh”]
#CMD /root/welcome-script.sh
#CMD ["bash"]
