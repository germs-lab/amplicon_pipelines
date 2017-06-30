# High-throughput Amplicon Gene Sequencing Pipelines and Processes    
Author: Fan Yang

## Included:  
1. Detailed explaination on the 16S gene and ITS gene sequence analysis. Include:   
    + Primer information    
    + Reasons behind the parameter selections   
    + Additional check points that are not included in the pipelines   
 
1. Bacterial 16S gene amplicon sequence process pipeline.   
    + pair-end assembling using pandaseq RDP extended version.   
    + chimera check using vsearch.   
    + clustering using cd-hit.   
    + if sequences were obtained from USDA, use: 
    ```
    16s_pipeline_makefile 
    ```

    + if sequences were obtained from ANL, use:
    ```
    anl_16S_pipeline.sh
    ```

2. Fungal ITS gene amplicon sequence process pipeline.  
    ```
    pipeline_ITS.sh   
    ``` 

3. Qsub script to run the pipelines on MSU HPCC.   
    ```
    hpc_qsub_16s_pipeline.sh  
    ``` 
  
4. Codes needed for pipelines.  

## Prerequesites:   
1. vsearch    
    + https://github.com/torognes/vsearch
        + we have version 2.4.3 in `/mnt/research/germs/softwares` on MSU HPCC.  

2. python 2.7 and Biopython   
    + MSU HPCC has python 2.7+ and Biopython.   
    + Or you can install your own Anaconda version.  
        + there is a version in `/mnt/research/germs/softwares` on MSU HPCC  

3. Java/1.7   
    + MSU HPCC has multiple versions. Do not use 1.8 version. 

4. R/2.15.1     
    + MSU HPCC also has multiple version of R. 2.15.1 works well.   
    + Or you can install your own Anaconda version.  

5. parallel   
    + MSU HPCC has gparallel. 

## Usage:
1. 16S makefile:   
    + copy `16s_pipeline_makefile` to the directory you would like your processed sequences to be stored in.  
    + rename `16s_pipeline_makefile` to `Makefile`. 
    + modify the directories of where things are in the `Makefile`.   
        + `DIR`: where processed sequences to be stored in.   
        + `ORI`: where the raw sequence files are.  
        + `SUBPROJECT`: the folder names you will create later to store samples from different projects in before clustering.   
        + `CODE`: the code directory in repository `amplicon_pipeline`.  
	+ `RDP`: the directory where RDP's public tools are. Shouldn't need to change this.   
	+ `CHIMERA_DB`: pathway to a 16S unaligned sequence database. I've been using RDP current release of unaligned bacterial 16S. 
	+ `VSEARCH`: pathwy to software `vsearch`. Also, shouldn't need to change this.
	+ `FN_DELIM`: the deliminators in your sequence file names that can be used to split the file names apart. 
	+ `FN_REV_INDEX`: count from right hand side, the number that determines the part of the file names were the sanme for pair-ended reads. 

## Obsolete
1. 16S pipeline in shell script using 64 bith usearch.aaa
    ```
    16s_seq_process_cdhit_method_hpc.sh 
    ```

2. Chimera removal pipeline if usearch 32bit (free version) is used. Run as part of the pipelines. See pipelines for adjustments.     
    ```
    chimera_removal_pipeline.sh  
    ```

**NOTE:**
1. Sequences obtained from USDA and ANL do not contain primers, linkers, or adapters. 

1. The qsub scripts contains all of the modules information need to be loaded if the pipelines are to be submitted as HPCC jobs.  

2. Only the chimera part of the 16S pipeline needs to be submitted. Everything else can be run on a development note. 
