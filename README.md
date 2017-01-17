# High-throughput Amplicon Gene Sequencing Pipelines and Processes    
Author: Fan Yang

## Included:  
1. Detailed explaination on the 16S gene and ITS gene sequence analysis. Include:   
    + Primer information    
    + Reasons behind the parameter selections   
    + Additional check points that are not included in the pipelines   
 
1. Bacterial 16S gene amplicon sequence process pipeline.   
    ```
    16s_seq_process_cdhit_method_hpc.sh
    ```

2. Fungal ITS gene amplicon sequence process pipeline.  
    ```
    pipeline_ITS.sh   
    ``` 

3. Qsub script to run the pipelines on MSU HPCC.   
    ```
    hpc_qsub_16s_pipeline.sh  
    ``` 

4. Chimera removal pipeline if usearch 32bit (free version) is used. Run as part of the pipelines. See pipelines for adjustments.     
    ```
    chimera_removal_pipeline.sh  
    ```
  
4. Codes needed for pipelines.  

## Prerequesites:   
1. usearch    
    + We are currently using RDP's paid 64 bit version (pathway is in the pieplines).   
    + If you only have the access to 32 bit version (free version), see pipelines for adjustments.   

2. python 2.7 and Biopython   
    + MSU HPCC has python 2.7+ and Biopython.   
    + Or you can install your own Anaconda version.  

3. Java/1.7   
    + MSU HPCC has multiple versions. Do not use 1.8 version. 

4. R/2.15.1     
    + MSU HPCC also has multiple version of R. 2.15.1 works well.   

5. parallel   
    + MSU HPCC has gparallel. 

**NOTE:**
The qsub scripts contains all of the modules information need to be loaded if the pipelines are to be submitted as HPCC jobs.  
