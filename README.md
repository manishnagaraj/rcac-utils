<h2> Utility Bash Scripts for use on NRL's RCAC Clusters </h2>

This repository contains bash scripts for launching, orchestrating, managing, and monitoring jobs on NRL's RCAC clusters. RCAC uses the Simple Linux Utility for Resource Management (SLURM), a system providing job scheduling and job management on compute clusters. With SLURM, a user requests resources and submits a job to a queue. The system will then take jobs from queues, allocate the necessary nodes, and execute them.

This README provides an overview of the prerequisites for using the cluster, a description of all provided scripts, and a few examples and common utilities.

---
<h3> Prerequisites </h3>
<h4> Access to the Cluster </h4>
Please verify you have access to the cluster before attempting to log in!

<h4> SSH Keys <h4>
Setup ssh keys on your machine using the following command:

```
ssh-keygen -t rsa
```

To copy this key to an RCAC cluster, use the following command:

```
ssh-copy-id $USER@$CLUSTER_NAME.rcac.purdue.edu
```

Verify your credentials using BoilerKey, and you're good to go! Logging in to the cluster now requires just your ssh key instead of BoilerKey+Duo!<br>
<b>NOTE:</b> Windows users may use the following command in PowerShell to emulate the function of ssh-copy-id:

```
type $PATH_TO_.SSH\id_rsa.pub | ssh $USER@$CLUSTER_NAME.rcac.purdue.edu "cat >> .ssh/authorized_keys"
```

---
<h3> Cloning and Setup </h3>
Clone this repo into your user space on the cluster by copying the ssh URL and then using

```
git clone $REPO_URL
```
Navigate to the repo and perform initial setup using

```
cd $PATH_TO_REPO
bash setup.bash
```
NOTE: For path invariance, the setup script will automatically move the cloned repo to your home directory (<code>/home/$USER</code>)

---
<h3> TLDR </h3>
To launch a job on the cluster, consider the following case:

The file <code>setup.bash</code> has been executed and all paths have been setup correctly (Note that at this point, this repository will be located in <code>/home/$USER</code>). The script file <code>file.py</code>, located in directory <code>/home/$USER/test</code> is to be executed in a conda environment named <code>env</code>.

Let us assume that the script requires 2 GPU cards, and as many CPUs as possible (14*N_GPU=28. For info on why 28, read the help message of joblauncher.bash)

Let us also assume that the script is to be run on the "cocosys" partition using the "cocosys" queue and that the user estimates a max runtime of 2.5 days. Additionally, the user determines that, in case the job runs for longer than 2.5 days, the necessary checkpoint and metadata saving will take ~97 seconds.

Given these considerations, the job should be launched using the following command:

```
bash joblauncher.bash -j jobsubmissionscript.sub -t python -d ~/test/ -f file.py -e env -g 2 -c 28 -q cocosys -p cocosys -T 2-12:00:00 -s 97
```

If email updates of job status are desired, then the <code>-m</code> flag should be added to the previous command.

A detailed list of command line args accepted by this script (or any of the scripts in this repo) may be found using
```
bash joblauncher.bash -h
```

NOTE: If your job is stuck in queue for a very long time, or if <code>scontrol show job $JOB_ID</code> contains the following message:
```
JobState=PENDING Reason=ReqNodeNotAvail,_Reserved_for_maintenance
```
then the cluster may be down. For updates regarding cluster status, please check the RCAC website <a href="https://www.rcac.purdue.edu/news/outages-and-maintenance?state=all&order_dir=desc">here</a>

---
<h3> Scripts </h3>

<h4> Setup Conda </h4>
RCAC clusters require use of the IT-managed conda module loadable using Lmod. While installing conda locally in your own directory <code>/home/$USER/</code> is possible, environments installed using your own conda installation will not be importable in code, i.e., they will not work.

To transfer existing environments from other machines onto RCAC clusters, on the other machine, export the env as a yml file using

```
conda env export $ENVNAME>$FILENAME.yml
```
and then re-install on the cluster using the provided bash script:

```
bash conda_env_installer.bash -f $YML_FILENAME
```
A detailed list of command line args accepted by this script may be found using

```
bash conda_env_installer.bash -h
```

<h4> Job Submission Script </h4>
Launching a job requires the creation of a "Job Submission Script", a template of which is provided here as <code>jobsubmissionscript.sub</code>. A detailed list of command line args accepted by this script may be found using

```
bash jobsubmissionscript.sub -h
```
NOTE: It is not necessary for a job submission script to accept command line arguments. The template file provides this functionality just for convenience.

A Job Submission Script is supposed to do three main things:
<ol>
  <li>Load all necessary Lmod modules. A list of available modules may be found using:

  ```
  module avail
  ```
  </li>
  <li>Activate the necessary conda environment
  
  ```
  conda activate $ENV_NAME
  ```
  </li>
  <li>Call the job script
  
  ```
  python helloWorld.py
  ```
  NOTE: SLURM provides functionality to send an OS signal to a job "n" seconds before termination (n $\in [0, 65535]$). This functionality is enabled by default (See the minimum working example given in the script helloWorld.py)
  </li>
</ol>
More information on job submission scripts, specifically for RCAC clusters, may be found <a href="https://www.rcac.purdue.edu/knowledge/gautschi/run/slurm/script">here</a>.

<h4> Launching a Job </h4>
To abstract out the details of the <code>sbatch</code> and <code>srun</code> SLURM commands, this repo provides a util script <code>joblauncher.bash</code>. A detailed list of command line args accepted by this script may be found using

```
bash joblauncher.bash -h
```

Jobs are launched using either the <code>srun</code> or the <code>sbatch</code> commands. Both these commands accept the same set of parameters.  The main difference is that <code>srun</code> is interactive and blocking (you get the result in your terminal and you cannot write other commands until it is finished), while <code>sbatch</code> is batch processing and non-blocking (results are written to a file and you can submit other commands right away).

If you use <code>srun</code> in the background with the & sign, then you remove the 'blocking' feature of <code>srun</code>, which becomes interactive but non-blocking. It is still interactive though, meaning that the output will clutter your terminal, and the <code>srun</code> processes are linked to your terminal. If you disconnect, you will loose control over them, or they might be killed (depending on whether they use stdout or not basically). And they will be killed if the machine to which you connect to submit jobs is rebooted.

If you use <code>sbatch</code>, you submit your job and it is handled by Slurm ; you can disconnect, kill your terminal, etc. with no consequence. Your job is no longer linked to a running process.

Use of the <code>sbatch</code> command is recommended on RCAC clusters. For convenience, we wrap the <code>sbatch</code> command in a wrapper file, a template of which is provided here as <code>joblauncher.bash</code>. Again, it is not necessary for the job launcher script to accept command line arguments. The template file provides this functionality just for convenience.

More info on the <code>srun</code> and <code>sbatch</code> commands may be found here: <a href="https://slurm.schedmd.com/srun.html">srun</a> and <a href="https://slurm.schedmd.com/sbatch.html">sbatch</a>

<h4> Monitoring Jobs </h4>
Launched jobs can be monitored using the <code>monitor.bash</code> file. A detailed list of command line args accepted by this script may be found using

```
bash monitor.bash -h
```
For more info about the commands used by this script, visit <a href="https://slurm.schedmd.com/squeue.html">squeue</a>.

<h4> Backing Up Files </h4>
The recommended file organisation on RCAC clusters is as follows:
<ol>
    <li> Code files and other important results: Your home directory (<code>/home/$USER</code>)</li>
    <li> Datasets and other large files: Your scratch directory (<code>/scratch/$CLUSTER_NAME/$USER/</code>)
    <li> Temporary/code-generated files: The temporary directory (<code>/tmp/</code>). For the dos and don'ts of <code>/tmp/</code>, read <a href="https://www.rcac.purdue.edu/knowledge/gautschi/storage/options/tmp">this</a></li>
</ol>
It is advisable to backup all code, result, and render files. Files can be backed up to FORTRESS, which is a tape-based backup media managed by Purdue IT. Since FORTRESS relies on tape, it is recommended to group large files into a tar archive before pushing them to FORTRESS. The provided script can do this automatically.

By default, backups in FORTRESS are saved in your FORTRESS home directory (<code>/home/$USER/</code>). For convenience, we impose the following path organisation:
<ol>
    <li> All tar archives are to be saved in <code>/home/$USER/archives/</code> </li>
    <li> All other files (note that these should only be large files such as datasets, model weights, etc.) are to be saved in <code>/home/$USER/largeFiles/</code> </li>
</ol>
You are free to use whatever directory structure you want inside these two directories.

To backup to FORTRESS, use

```
 bash backup.bash $FILES_TO_BACKUP
```
NOTE: The backup script accepts wildcards (the * character), i.e., if you want to backup multiple files named file1, file2, ...., filen, then all of them can be backed up in a single call to <code>backup.bash</code> using

```
 bash backup.bash file*
```
A detailed list of command line args accepted by this script may be found using:

```
bash backup.bash -h
```
If you have never used tar/server keytabs/sftp/tape archives before, the provided script is designed to guide you through the steps needed to backup data to FORTRESS. Simply follow the instructions on screen!

<h4> Retrieving Backups </h4>
To retrieve backed-up file(s), use the script <code>retrieve_backup.bash</code>. A detailed list of command line args accepted by this script may be found using:

```
bash retrieve_backup.bash -h
```
NOTE: This script provides auto-untarring functionality when retrieving tar archives.

---
<h3> Examples </h3>
Consider the following case:

The file <code>setup.bash</code> has been executed and all paths have been setup correctly (Note that at this point, this repository will be located in <code>/home/$USER</code>). The script file <code>file.py</code>, located in directory <code>/home/$USER/test</code> is to be executed in a conda environment named <code>env</code>.

Let us assume that the script requires 2 GPU cards, and as many CPUs as possible (14*N_GPU=28. For info on why 28, read the help message of joblauncher.bash)

Let us also assume that the script is to be run on the "ai" partition and that the user estimates a max runtime of 2.5 days. Additionally, the user determines that, in case the job runs for longer than 2.5 days, the necessary checkpoint and metadata saving will take ~97 seconds.

Given these considerations, the job should be launched using the following command:

```
bash joblauncher.bash -j jobsubmissionscript.sub -t python -d ~/test/ -f file.py -e env -g 2 -c 28 -p ai -T 2-12:00:00 -s 97
```

Keeping all other conditions the same, if the script were to change from <code>file.py</code> to <code>file.bash</code>, then the job should be launched using

```
bash joblauncher.bash -j jobsubmissionscript.sub -t bash -d ~/test/ -f file.bash -e env -g 2 -c 28 -p ai -T 2-12:00:00 -s 97
```
NOTE: In most cases, a majority of the supported command line arguments will be left at their default values. All the arguments supported by the file <code>joblauncher.bash</code> are expanded in the above example, just for convenience.

---
<h3> Common Utilities </h3>
To display a list of your active jobs (running/enqueued), use

```
squeue -u $USER
```

If your job is waiting in the SLURM queue, you can get an estimate of its start time using

```
scontrol show job $JOB_ID | grep StartTime
```

To cancel a running/pending job, use

```
scancel $JOB_ID
```
---
<h3> Common Pitfalls </h3>
Take a look at the issues for answers to the most common pitfalls. If your problem does not appear there, do raise a fresh issue!

