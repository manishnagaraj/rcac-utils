#!/bin/bash

# FILENAME:  conda_env_installer_in_scratch

# necessary loading. DO NOT MODIFY
source config_rcac.bash

# Hardcoded base path for Conda environments
# <<< THIS IS THE HARDCODED PATH >>>
DEFAULT_ENV_BASE_PATH="/scratch/gautschi/mnagara"

# system constants. DO NOT CHANGE
USER=$(whoami)
FLAG=false # Used for Anaconda3 deletion confirmation

# usage help message
usage() {
    echo "usage: $0 [-h] [-f YML_FILENAME] [-p YML_PATH] [-n ENV_NAME]" 1>&2;
    echo "This script installs Conda environments into a pre-defined scratch location: ${DEFAULT_ENV_BASE_PATH}"
    echo "-h: Display help message"
    echo "-f YML_FILENAME: Name of env yml file. Defaults to 'environment.yml'"
    echo "-p YML_PATH: Path to yml file. Defaults to '${HOME}/rcac-utils'"
    echo "-n ENV_NAME: Name of env to be created. This will also be the subdirectory name under ${DEFAULT_ENV_BASE_PATH}. Defaults to 'environment'."
    exit 1;
}

# arg init
YML_FILENAME=environment.yml
YML_PATH=$HOME/rcac-utils
ENV_NAME=environment

# read args - Removed -P option
while getopts "hf:p:n:" opts; do
    case "${opts}" in
        h)  usage;;
        f)  YML_FILENAME=$OPTARG;;
        p)  YML_PATH=$OPTARG;;
        n)  ENV_NAME=$OPTARG;;
        *)  usage;;
    esac
done

# Validate that YML_PATH and YML_FILENAME point to an existing file
if [ ! -f "${YML_PATH}/${YML_FILENAME}" ]; then
    echo -e "[${yellow}ERROR${nc}] YAML file not found: ${YML_PATH}/${YML_FILENAME}"
    exit 1
fi

# Check for existing Anaconda3 installation in HOME
if [ -d "$HOME/anaconda3" ]; then
    read -p "$(echo -e "[${yellow}WARNING${nc}] Anaconda installation found in $HOME/anaconda3! This conflicts with Lmod module conda and causes job failures. Should it be deleted? (y/n) ")" confirm
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        echo "Removing $HOME/anaconda3..."
        rm -rf "$HOME/anaconda3/"
        echo "Removing old Anaconda installation scripts from $HOME..."
        rm -f "$HOME/Anaconda*.sh"
    else
        echo -e "[${yellow}INFO${nc}] User chose not to remove conflicting $HOME/anaconda3 directory."
        echo -e "[${yellow}ERROR${nc}] Script cannot proceed due to potential conflicts. Exiting."
        exit 1 # Exit the script if user chooses 'N' or anything other than 'Y/Yes'
    fi
fi


module load conda

echo -e "[${green}INFO${nc}] Conda executable path: $(which conda)"
echo -e "[${green}INFO${nc}] Conda base installation path: $(conda info --base)"

module load cuda # To ensure the correct version of pytorch gets installed
if [ $? -ne 0 ]; then
    echo -e "[${yellow}WARNING${nc}] Failed to load cuda module. This might affect PyTorch installation if it relies on a specific CUDA version."
fi

# Construct the full path for the new environment
FULL_ENV_PATH="${DEFAULT_ENV_BASE_PATH}/${ENV_NAME}"

echo -e "[${green}INFO${nc}] Preparing to create Conda environment '${ENV_NAME}' at prefix: ${FULL_ENV_PATH}"

# Create the base directory if it doesn't exist
mkdir -p "${DEFAULT_ENV_BASE_PATH}"
if [ $? -ne 0 ]; then
    echo -e "[${yellow}ERROR${nc}] Failed to create base directory: ${DEFAULT_ENV_BASE_PATH}"
    exit 1
fi

# Create env using the hardcoded base path and the environment name as a subdirectory
conda env create --prefix "${FULL_ENV_PATH}" --file "${YML_PATH}/${YML_FILENAME}"

if [ $? -eq 0 ]; then
    echo -e "[${green}DONE${nc}] Environment '${ENV_NAME}' created successfully at ${FULL_ENV_PATH}."
    echo -e "[${green}INFO${nc}] To activate this environment, use: conda activate ${FULL_ENV_PATH}"
else
    echo -e "[${yellow}ERROR${nc}] Failed to create Conda environment '${ENV_NAME}' at ${FULL_ENV_PATH}."
    exit 1
fi

exit 0