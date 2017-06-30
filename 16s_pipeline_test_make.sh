#!/bin/sh --login
#PBS -l nodes=4:ppn=4
#PBS -l walltime=2:00:00
#PBS -l mem=256gb
#PBS -q main
#PBS -M snisiarc@gmail.com
#PBS -m abe
#PBS -N test

module load gparallel/20131022

cd /mnt/research/germs/pipeline_test

make chimera_ref
make remapping

