# Install Spark on DGX

## Why

Every Spark version has its own dependencies and features. Not everything is backwards compatible. The Spark version also has a huge dependency how to configure SparkSessions. On the one hand, we always try to be at the latest Spark version in order to benefit from the latest features and bug fixes. On the other hand, we have a lot potential users who cannot be synchronized to one Spark version in a very short time because potentially every SparkApp has different efforts in migrating to the next Spark version.

That is why every user needs to take of installing Spark for his/her own user themself. Also upgrading/migrating falls into the responsiblity of the users.

But no worries. This manual is used to provide easy steps about installing and upgrading spark including some dependency management.

## Installing Spark locally (on DGX) for your user

- [Here](https://spark.apache.org/downloads.html) is the official download page. You can get the download urls there. It automatically shows the latest version.
- Spark-rapids (for gpu support) is currently only compatible with Spark version `3.3.0` 
    - So the archive can be found [here](https://archive.apache.org/dist/spark/spark-3.3.0/) as an example where we need `spark-3.3.0-bin-hadoop3.tgz`
- You are in your home directory:
```
cd ~
```
- Install Spark via terminal with fire and forget commands:
```
wget https://archive.apache.org/dist/spark/spark-3.3.0/spark-3.3.0-bin-hadoop3.tgz
tar xvf spark-3.3.0-bin-hadoop3.tgz
rm spark-3.3.0-bin-hadoop3.tgz
mv spark-3.3.0-bin-hadoop3 $HOME/spark
```
- One time it is recommended to configure environmental variables:
```
echo "export SPARK_HOME=$HOME/spark" >> ~/.profile
source ~/.profile
echo "export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin" >> ~/.profile
echo "export PYSPARK_PYTHON=/usr/bin/python3" >> ~/.profile
source ~/.profile
```
- Lastly, install the according python package with pip:
```
python3 -m venv venv
source venv/bin/activate
pip install --user pyspark==3.3.0
```
- Test/verify:
```
pyspark
version 3.3.0
exit()
```

### Dependency management

We recommend at least S3 dependencies.
```
wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.2/hadoop-aws-3.3.2.jar -O $HOME/spark/jars/hadoop-aws-3.3.2.jar
wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.1026/aws-java-sdk-bundle-1.11.1026.jar -O $HOME/spark/jars/aws-java-sdk-bundle-1.11.1026.jar
```

The dependency management with Spark can be tricky and confusing. Just an example for the S3 dependencies:
- Spark 3.3.0 has out of the box hadoop version 3.3.2 included (that is why we need `hadoop-aws-3.3.2.jar` and not `hadoop-aws-3.3.0.jar`):
```
ls -la ~/spark/jars | grep hadoop
hadoop-client-api-3.3.2.jar
```
- In the [Maven repo](https://mvnrepository.com/artifact/org.apache.hadoop/hadoop-aws/3.3.2) you can find additional dependencies under "Compile Dependencies": `aws-java-sdk-bundle` in version `1.11.1026` which needs to be downloaded as well.

## Upgrade Spark version

- Here we assume you already have Spark version 3.2.2 installed and it needs to be upgraded to version 3.3.0
- You are in your home directory:
```
cd ~
```
- First uninstall old python package:
```
pip uninstall pyspark==3.2.2
```
- Backup old Spark folder:
```
mv spark spark3.2.2
```
- Install new Spark version via terminal with fire and forget commands:
```
wget https://archive.apache.org/dist/spark/spark-3.3.0/spark-3.3.0-bin-hadoop3.tgz
tar xvf spark-3.3.0-bin-hadoop3.tgz
rm spark-3.3.0-bin-hadoop3.tgz
mv spark-3.3.0-bin-hadoop3 $HOME/spark
```
- Lastly, install the according python package with pip:
```
python3 -m venv venv
source venv/bin/activate
pip install --user pyspark==3.3.0
```
- Test/verify:
```
pyspark
version 3.3.0
exit()
```

Do not forget your dependency management. It does not differ from the install section.