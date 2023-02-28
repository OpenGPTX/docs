from pyspark.sql import SparkSession
import os
import random
home = os.environ["HOME"]
spark_master=os.environ["MASTER_URL"]

# This is required to add a "i" to the hostname
tmp=os.environ["HOSTNAME"].split("."); tmp[0]+="i"; spark_driver_hostname=".".join(tmp)

spark = SparkSession \
    .builder \
    .appName("My SparkSession") \
    .config("spark.master", spark_master) \
    .config("spark.driver.memory", "10g") \
    .config("spark.driver.host", spark_driver_hostname) \
    .config("spark.executor.memory", "400g") \
    .getOrCreate()

sc=spark.sparkContext

def inside(p):
    x, y = random.random(), random.random()
    return x*x + y*y < 1

NUM_SAMPLES=10000000
count = sc.parallelize(range(0, NUM_SAMPLES)) \
             .filter(inside).count()
print("Pi is roughly %f" % (4.0 * count / NUM_SAMPLES))
