#!/bin/sh --login
#PBS -l nodes=4:ppn=4
#PBS -l walltime=48:00:00
#PBS -l mem=256gb
#PBS -q main
#PBS -M snisiarc@gmail.com
#PBS -m abe
#PBS -N 16s_seq_process_pipeline_hpc

module load Java/1.7.0_51
module load CDHIT/4.6.1
module load R/2.15.1
module load gparallel/20131022

cd /mnt/home/yangfan1/repos/amplicon_pipelines

bash 16s_seq_process_cdhit_method_hpc.sh
