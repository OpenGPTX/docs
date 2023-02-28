#!/bin/bash

#SBATCH --partition=develbooster
#SBATCH --account=opengptx-elm
#SBATCH --nodes=2
#SBATCH --tasks-per-node=1
#SBATCH --time=02:00:00
#SBATCH --gres gpu
#SBATCH --job-name spark-cluster
#SBATCH --mail-user="your@email.com"
#SBATCH --mail-type=ALL

#module load Stages/2023  GCC  OpenMPI Spark
source ./spark_env/activate.sh

JOB="$SLURM_JOB_NAME-$SLURM_JOB_ID"
mkdir -p $SLURM_SUBMIT_DIR/spark-history
export SPARK_WORKER_DIR="$SLURM_SUBMIT_DIR/spark-history/$JOB/worker"
export SPARK_LOG_DIR="$SLURM_SUBMIT_DIR/spark-history/$JOB/log"
export SPARK_CONF_DIR=$SLURM_SUBMIT_DIR

# We need Hostnames with an appended "i" at the end of the first part of the 
# Hostname. This is done here. If not,export  SPARK_MASTER_HOST=`hostname` would be enough
export SPARK_MASTER_HOST=`hostname | sed -E "s/(.*)\.(.*)/\1i.\2/g"`
export SPARK_MASTER_PORT="4124"

#Change this to alter the number of workers and the number their max number of threads
export SPARK_WORKER_CORES=92
export SPARK_WORKER_INSTANCES=1 

#These options seem not to have any effect. Not clear why.
#export SPARK_WORKER_MEMORY="20G"
#export SPARK_EXECUTOR_MEMORY="10G"

export MASTER_URL="spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}"
mkdir -p ${SPARK_LOG_DIR}
export > ${SPARK_LOG_DIR}/env.txt

echo "------------ Starting Spark Server -------------"
echo "MASTER_URL: $MASTER_URL"
echo "------------------------------------------------"
start-master.sh
start-history-server.sh


export SPARK_NO_DAEMONIZE=1

srun bash -c 'export SPARK_PUBLIC_DNS=`hostname | sed -E "s/(.*)\.(.*)/\1i.\2/g"` ; 
              start-worker.sh $MASTER_URL;'
#              export SPARK_LOCAL_IP=`getent ahosts $SPARK_PUBLIC_DNS | head -n1 | cut -d " " -f 1`;

# This script can be used for workers that start in Daemon
# Mode. 
#. wait-worker.sh 
# Then we need to sleep.
# sleep infinity
 


