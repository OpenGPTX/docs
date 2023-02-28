## Guide  to run and monitor spark jobs on JUWELS

### Creating virtual python environments on JUWELS
Refer this repo: [venv-template](https://gitlab.jsc.fz-juelich.de/kesselheim1/sc_venv_template) and follow the guide mentioned in the repo


### Running spark jobs on JUWELS

Refer this repo: [spark-examples](https://gitlab.jsc.fz-juelich.de/AI_Recipe_Book/recipes/spark-examples) and follow the guide.

For the purposes of this documentation, there have been some modifications to the **spark-examples** repo and some of the documentation has been summarized. 

1. Prepare the virtual environment to install required Python dependencies.

   - `cd spark-examples` which contains a simple spark application that calculates the value of Pi using spark
   - `cd spark_env` inside the spark-examples folder
   - Edit `requirements.txt`
   - Create the virtual environment by calling `./setup.sh`
   - To recreate the virtual environment, simple delete the folder `./venv`

2. Pick the Number of nodes by adjusting the line `#SBATCH --nodes=2` in `start_spark_cluster.sh` or `start-develbooster-spark.sh` already is configured to run on development node where one can get resources without waiting a lot but is limited to 2 hrs of compute time.

### Execution
To start your spark cluster on the cluster, simply run:

```bash
sbatch start-develbooster-spark.sh
```

Note: The `start-develbooster-spark.sh` bash script is slurm batch script and it has all the configurations that you need to start a spark job on the JUWELS cluster. More info about how to write a Batch system using Slurm can be found here: [Juwels slurm batch system](https://apps.fz-juelich.de/jsc/hps/juwels/batchsystem.html)


Once you have submitted the batch job, a job id is displayed in the console. One has to wait for a while until resources are allocated. The `start-develbooster-spark.sh` has these variables defined

```bash
#SBATCH --mail-user="your@email.com""
#SBATCH --mail-type=ALL
```

You should get an email notification as soon as your job is run. You can also open another terminal window, ssh into the juwels login node and watch when a resource has been allocated by executing: `watch -n 5 squeue --me` which updates every 5 seconds.

### Running the python scripts

Once resources have been allocated, you should see something like this:

```bash
[username@jwlogin23 spark-examples]$ watch -n 5 squeue --me
JOBID   PARTITION NAME     USER      ST TIME  NODES NODELIST(REASON)
6525353 develboos spark-cl username  R  00:01 2     jwb[0129,0149]
```
In the above the output, 0129 is the master node and 0149 is the worked node.

In a terminal where you sshed into JUWELS, and submitted the slurm batch script, activate the python venv and run this command: `export MASTER_URL=spark://jwb0129i.juwels:4124`

Next, just run the python script: `python pyspark_pi.py`. This job should take few seconds and an output with the value of Pi will be shown.

### Spark history server

The Spark History Server is a User Interface that is used to monitor the metrics and performance of the completed Spark applications. There were some configuration changes that one has to do ensure that the history server runs smoothly.

In start-develbooster-spark.sh, there was configuration `export SPARK_CONF_DIR=$SLURM_SUBMIT_DIR` where the $SLURM_SUBMIT_DIR contains a spark-defaults.conf

```conf
spark.driver.memory 2g
spark.executor.memory 2g
spark.executor.cores 2
spark.yarn.executor.memoryOverhead 512
spark.default.parallelism 4

spark.history.ui.port                   18080
spark.history.acls.enable               true
spark.history.provider                  org.apache.spark.deploy.history.FsHistoryProvider
spark.history.retainedApplications      100
spark.history.fs.update.interval        10s
spark.eventLog.enabled                  true
spark.eventLog.dir                      file:///p/home/jusers/kamathbola1/juwels/project/kamathbola1/repos/spark-examples/spark-history
spark.history.fs.logDirectory           file:///p/project/opengptx-elm/kamathbola1/repos/spark-examples/spark-history
```
`spark.eventLog.enabled`, `spark.eventLog.dir` and `spark.history.fs.logDirectory` are the important parameters that have to be defined in order to get the spark history server working

To actually view the history server one has to port forward and ssh jump on the master node of the spark server. E.g: In this case the command would be something like this: `ssh -L 18080:localhost:18080 -L 8080:localhost:8080 USERNAME@jwb0129i.juwels -i /path/to/private/sshkey -J USERNAME@juwels-booster.fz-juelich.de`

And then in your browser, just goto localhost:18080 to view the spark history server.