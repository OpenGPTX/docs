#!/bin/bash

#SBATCH --partition=develbooster
#SBATCH --account=atmlaml
#SBATCH --nodes=2
#SBATCH --tasks-per-node=1
#SBATCH --time=00:60:00
#SBATCH --gres gpu
#SBATCH --job-name spark-cluster
 
#module load Stages/2023  GCC  OpenMPI Spark
source ./spark_env/activate.sh

JOB="$SLURM_JOB_NAME-$SLURM_JOB_ID"
export SPARK_WORKER_DIR="$SLURM_SUBMIT_DIR/$JOB/worker"
export SPARK_LOG_DIR="$SLURM_SUBMIT_DIR/$JOB/log"

# We need Hostnames with an appended "i" at the end of the first part of the 
# Hostname. This is done here. If not,export  SPARK_MASTER_HOST=`hostname` would be enough
export SPARK_MASTER_HOST=`hostname | sed -E "s/(.*)\.(.*)/\1i.\2/g"`
export SPARK_MASTER_PORT="4124"

#Change this to alter the number of workers and the number their max number of threads
export SPARK_WORKER_CORES=92
export SPARK_WORKER_INSTANCES=1 

#These options seem not to have any effect. Not clear why.
#export SPARK_WORKER_MEMORY="10G"
#export SPARK_EXECUTOR_MEMORY="10G"

export MASTER_URL="spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}"
mkdir -p ${SPARK_LOG_DIR}
export > ${SPARK_LOG_DIR}/env.txt

echo "------------ Starting Spark Server -------------"
echo "MASTER_URL: $MASTER_URL"
echo "------------------------------------------------"
start-master.sh
start-history-server.sh

echo "----------- How to test with spark shell ------"
echo "./spark_env/activate.sh"
echo "export MASTER_URL=$MASTER_URL"
echo "spark-shell --master \$MASTER_URL"
echo "# Now your shell should connect to the spark master"
echo
echo "In the shell you can now execute the following test script"
echo
echo ">>>>"
echo "val NUM_SAMPLES=1000000"
echo "val count = sc.parallelize(1 to NUM_SAMPLES).filter { _ =>"
echo "  val x = math.random"
echo "  val y = math.random"
echo "  x*x + y*y < 1"
echo "}.count()"
echo "println(s\"Pi is roughly \${4.0 * count / NUM_SAMPLES}\")"
echo "<<<<"
echo "------------------------------------------------"
echo
echo "----------- How to test with pyspark ------"
echo "./spark_env/activate.sh"
echo "export MASTER_URL=$MASTER_URL"
echo "python pyspark_pi.py"
echo "------------------------------------------------"
echo 
echo "---------- How to kill -------------------------"
echo scancel $SLURM_JOB_ID
echo "------------------------------------------------"
echo 
echo 
echo
echo "------------ Starting Spark Workers ------------"
echo "MASTER_URL: $MASTER_URL"
echo "------------------------------------------------"

export SPARK_NO_DAEMONIZE=1

srun bash -c 'export SPARK_PUBLIC_DNS=`hostname | sed -E "s/(.*)\.(.*)/\1i.\2/g"` ; 
              start-worker.sh $MASTER_URL;'
#              export SPARK_LOCAL_IP=`getent ahosts $SPARK_PUBLIC_DNS | head -n1 | cut -d " " -f 1`;

# This script can be used for workers that start in Daemon
# Mode. 
#. wait-worker.sh 
# Then we need to sleep.
# sleep infinity
 

