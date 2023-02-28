# Knowledge Exchange: Spark UI vs Sparkmonitor


## Spark UI

- Not live, i.e. you need to refresh the page to get the newest data
- You can monitor ramp up (or termination) of executors, i.e. see the state of the executor and their timeline
- DAG visualization - separate stages and their relation
- You can see which Java code is being executed (mostly useless)
- Time measurement for each stage on each executor which is helpful for imbalanced dataset and optimization
- *GC Time* - high percentage out of total time is bad, reason for investigation
- *Storage* tab not relevant for batch jobs.  It's shown only when a table is registered with Spark/Hive
- *Environment* tab - contains all configs and vars, even default values; good for double-checking from dev/user side
- *Executors* tab - "do i have the right amount of executors"
    - dead or alive visible
    - if too slow, investigate shuffles
    - In general it's a "history" (kinda) server
- *SQL* tab - a lot of information about query exection, best place to look for optimizations, but also non-trivial ones
- Tips/Tricks
    - Optimization advice - intermediate writing of data to storage
    - Jobs - ideally the only tab to look at
    - Overall - a lot of information, a bit difficult to handle all
    - Data gets lost when Driver crashes
- According to Jonas, we should have both Spark UI and Sparkmonitor

## Sparkmonitor

- It's a subset of Spark UI, but shown in real time
- You do not need to switch between pages (e.g., Spark UI and notebook)
- Live tracking of executors' cores and active tasks for the duration of the job
- It adds a "bit" more data visualization to the specific cell/code - interactive graph for the relative load, e.g. 2 out of X cores are busy
- It shows the right information "on the spot" (specific cell/code)
- ~~It could be an enabler for Spark UI using "The Notebook Webserver Extension - A Spark Web UI proxy"~~ (UPDATE: original implementation is faulty with hardcoded URL)
- Flaky connection - sometimes on kernel restart, connection to monitor pluging gets lost and requires another kernel restart