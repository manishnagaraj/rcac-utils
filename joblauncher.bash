#!/bin/bash

# Copyright (c) 2025, Amogh S. Joshi

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# FILENAME:  joblauncher


# necessary imports
source config_rcac.bash

# system constants. DO NOT CHANGE
QUEUE=kaushik
JOB_FILE_PATH=$HOME/rcac-utils
USER=$(whoami)
FLAG=false

# file name setup
JOB_NAME="${USER}"
OUT_FILE="${HOME}/joboutput/${JOB_NAME}"
ERR_FILE="${HOME}/joboutput/${JOB_NAME}"

# usage help message
usage() {
	echo "usage: $0 [-h] [-j JOB_SUBMISSION_SCRIPT] [-d SCRIPT_DIR] [-f SCRIPT_FILE] [-e ENV_NAME] [-g N_GPUS] [-c N_CPUS] [-p PARTITION] [-t MAX_TIME]" 1>&2;
	echo "-h: Display help message"
	echo "-j JOB_SUBMISSION_SCRIPT: Name of job submission script. Defaults to 'jobsubmissionscript.sub'"
	echo "-d SCRIPT_DIR: Absolute path to directory containing the python/other code script to be run. Defaults to '${HOME}'"
	echo "-f SCRIPT_FILE: Name of python file to run. Defaults to helloWorld.py"
	echo "-e ENV_NAME: Name of the script's conda environment. Defaults to 'base'"
	echo "-g N_GPUS: Number of GPU cards required. Defaults to 1."
	echo "-c N_CPUS: Number of CPUs required. Defaults to 32."
	echo "-p PARTITION: Name of partition to run on. Defaults to 'ai'"
	echo -e "-t MAX_TIME: Max job time. After executing for this much time, the job is killed.\n\tSpecify in dd-hh:mm:ss format. Defaults to 6:00:00 (6 hrs)\n\tUse the USR1 signal as shown in helloWorld.py to save checkpoints before termination."
	exit 1;
}

# arg init
N_GPUS=1
N_CPUS=32
PARTITION=ai
MAX_TIME=6:00:00
ENV_NAME=base
JOB_SUBMISSION_SCRIPT=jobsubmissionscript.sub
SCRIPT_DIR=$HOME
SCRIPT_FILE=helloWorld.py

# read args
while getopts "hj:d:f:e:g:c:p:t:" opts; do
	case "${opts}" in
		h)	usage;;
		j)	JOB_SUBMISSION_SCRIPT=$OPTARG;;
		d)  SCRIPT_DIR=$OPTARG;;
		f)	SCRIPT_FILE=$OPTARG;;
		e)	ENV_NAME=$OPTARG;;
		g)  N_GPUS=$OPTARG;;
		c)  N_CPUS=$OPTARG;;
		p)	PARTITION=$OPTARG;;
		t)	MAX_TIME=$OPTARG;;
		*)	usage;;
	esac
done

# essential computation
DIV=$((${CLUSTER}_${PARTITION}))
N_NODES=$(((($N_CPUS+$DIV-1))/$DIV))

# protect compute resources!
if [[ $N_NODES -gt 2 ]]; then
	read -p "$( echo -e "["${yellow}"WARNING"${nc}"] The requested number of tasks requires more than one node. MPI-enabled code necessary to run multi-node workloads. Non-MPI code will result in wasted compute resources. Is your code MPI-enabled? (y/n): ")" confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || FLAG=true
	if $FLAG; then
		echo -e "[${red}FATAL${nc}] Attempted multi-node run with non-MPI workload. Exiting..."
		exit 1
	fi
fi

# call to sbatch to launch the job
# sbatch args are arranged thus:
# sbatch \
# 	-p [PARTITION] : Name of compute partition on which to run job
#	-q [QOS_LEVEL] : Quality-of-Service level
#	--job-name=[JOB_NAME] : User-defined job name
#	--output=[OUTPUT_LOG_FILE_NAME] : Name of output log file along with its absolute path
#	--error=[ERROR_LOG_FILE_PATH] : Name of error log file along with its absolute path
#	--gpus-per-node=[N_GPUS] : Number of GPU cards to allocate to the job
#	--gres=[GEN_HDWARE_RQMT] : General Hardware requirements of the job. Jobs requiring GPUs must set this to "gpu"
#	-t [WALL_CLK_TIME] : Wall clock time. Once started, a job will run for exactly this much time before it is killed and its resurces are released. If a job terminates earlier than this time, then resources are released immediately.
#	--signal=[SIG_NAME@TIME] : When this arg is used, SLURM sends signal "SIG_NAME" to the script "TIME" seconds before WALL_CLK_TIME is reached. To prevent data loss, users must implement methods to catch this signal to save state and perform other necessary cleanup.
#	--nodes=[N_NODES] : Minimum number of nodes to allocate to the job. (Max nodes can also be spcified, consult man page)
#	-n [N_TASKS] : Max number of tasks launched by the job.
#	-A [QUEUE] : Name of queue to submit job to. NRL's queue is named "kaushik"
#
#	For more info about sbatch, consult the sbatch man page using "man sbatch"
sbatch \
	-p $PARTITION -q normal \
	--job-name="${JOB_NAME}_%j" --output="${OUT_FILE}_%j.log" --error="${ERR_FILE}_%j.log" \
	--gpus-per-node=$N_GPUS --gres=gpu:$N_GPUS -t $MAX_TIME --signal=B:SIGUSR1@60 --nodes=$N_NODES -n$N_CPUS -A $QUEUE \
	$JOB_FILE_PATH/${JOB_SUBMISSION_SCRIPT} -e $ENV_NAME -d $SCRIPT_DIR -f $SCRIPT_FILE
