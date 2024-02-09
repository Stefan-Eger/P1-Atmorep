#!/bin/bash -x
#SBATCH --account=p200233
#SBATCH --time=01:59:59
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH --gres=gpu:4
#SBATCH --partition=gpu
#SBATCH --qos=default
#SBATCH --output=logs/forecast-%x.%j.out
#SBATCH --error=logs/forecast-%x.%j.err

#export PYTHONPATH=${SLURM_SUBMIT_DIR}

source ${SLURM_SUBMIT_DIR}/pyenv/bin/activate

ml purge
ml Python
ml GCC
ml OpenMPI
#ml PyTorch


export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export CUDA_VISIBLE_DEVICES=0,1,2,3

# so processes know who to talk to
MASTER_ADDR="$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)"
# Get IP for hostname.
export MASTER_ADDR="$(nslookup "$MASTER_ADDR" | grep -oP '(?<=Address: ).*')"

export NCCL_DEBUG=TRACE

echo "Starting job."
echo "Number of Nodes: $SLURM_JOB_NUM_NODES"
echo "Number of Tasks: $SLURM_NTASKS"
date

srun --label --cpu-bind=v --accel-bind=v python -u ${SLURM_SUBMIT_DIR}/atmorep/core/evaluate.py > output/output_${SLURM_JOBID}.txt

echo "Finished job."
date