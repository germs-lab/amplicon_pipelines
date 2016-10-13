Gene-Targetted Sequence Analysis
====================

This protocol is specifically modified to use with Pat Schloss method of gene targetting sequencing results from which 3 fastq.gz files were yielded:    
+ XXXX_I1_XXX.fastq.gz (index file that stores barcodes)    
+ XXXX_R1_XXX.fastq.gz (forward paired-end sequence, no tag nor linker/primer combo)    
+ XXXX_R2_XXX.fastq.gz (reverse paired-end sequence, no tag nor linker/primer combo)    

General Procedures:   
------------------
1. Use RDP's pandaseq (RDP_Assembler) to construct good quality full length sequences (assem.fastq).   
2. Use RDPTools/SeqFilters to check barcodes quality and split them into different sample directories (ONLY barcodes need to be reverse complimented, sequences are in the correct orientation).   
3. Bin assembled sequences into different sample files.   
4. Check for chimeras.  
5. Use RDPTools/Classifiers to pick taxonomy, use RDPToools/AlignmentTools to align sequences and then cluster using RDPTools/mcCluster.   
6. R for analysis

Detailed Procedures:   
-------------------
1. **RDP_assembler**  
    1. First run with minimal constrants:i   
        ```
        ~/RDP_Assembler/pandaseq/pandaseq -N -o 10 -e 25 -F -d rbfkms -f /PATH/TO/Undetermined_S0_L001_R1_001.fastq.gz -r /PATH/TO/Undetermined_S0_L001_R2_001.fastq.gz 1> IGSB140210-1_assembled.fastq 2> IGSB140210-1_assembled_stats.txt
        ```

        You should look at the stat output. If you are analysing for 16S, pay close attention to sequences that are shorter than 250b and longer than 280b. Majority of sequences outside of the 250-280 range are eukaryotic. Some are bacterial but with high uncertainties.Same case with ITS. If you blast anything less 250 or greater than 280, you can see that anything with a good match and high sequence coverage lands within 250-280 range. Anything longer than 280 has an extremely suspecious trunk of unknow match int he middle. Unlike 16S, ITS1F/ITS2 is known to amplify a substantial amount of plant genes. If it's a chimera between fungi and plant, reference based uchime would not be able to eliminate it. I also found that the combination of quality scores and seq length matters more than overlaps.  

    2. You could analyze your assembled read stat file by:
        ```
        python ~/Documents/Fan/code/rdp_assem_stat_parser.py IGSB140210-1_assembled_stats.txt
        ```
 
        You may need to modify the python script for different parameters.

    3. Run assembler again with comfirmed parameters:
        ```
        ~/RDP_Assembler/pandaseq/pandaseq -N -o 10 -e 25 -F -d rbfkms -l 250 -L 280 -f /PATH/TO/Undetermined_S0_L001_R1_001.fastq.gz -r /PATH/TO/Undetermined_S0_L001_R2_001.fastq.gz 1> IGSB140210-1_assembled_250-280.fastq 2> IGSB140210-1_assembled_stats_250-280.txt
        ```

        For ITS, I used minimal overlap of 80 and minimal merged length of 122. The large variations in fungal ITS regions requires a larger range to cover the broad taxonomy distribution.
        ```
        ~/RDP_Assembler/pandaseq/pandaseq -N -o 80 -e 25 -F -d rbfkms -l 122 -f ~/Documents/ElizabethData/COBS_ITS/uploads/Undetermined_S0_L001_R1_001.fastq.gz -r ~/Documents/ElizabethData/COBS_ITS/uploads/Undetermined_S0_L001_R2_001.fastq.gz 1> ITS_assembled_o80_min122.fastq 2> ITS_assembled_o80_min122_stats.txt
        ``` 

    4. make sure the number of good assembled sequence in assembled.fastq is the same as the OK number in stats.txt file   
        ```
        grep -c "@M0" IGSB140210-1_assembled_250-280.fastq  
        ```

2. **RDPTools: SeqFilters**   
    This step trims off the tag and linker sequences. Final files are splited into folders named by individual samples.    
    
    **Need:**   
    1. map file from Argonne
        ```
        #SampleID       BarcodeSequence LinkerPrimerSequence    Description
        DC1     TCCCTTGTCTCC    CCGGACTACHVGGGTWTCTAAT  DC1
        DC2     ACGAGACTGATT    CCGGACTACHVGGGTWTCTAAT  DC2
        DC3     GCTGTACGGATT    CCGGACTACHVGGGTWTCTAAT  DC3
        DC4     ATCACCAGGTGT    CCGGACTACHVGGGTWTCTAAT  DC4
        DC5     TGGTCAACGATA    CCGGACTACHVGGGTWTCTAAT  DC5
        ```

        Tags example: `TCCCTTGTCTCC`   

        16S V4 Forward primer: 515F `GTGCCAGCMGCCGCGGTAA`
        
        16S V4 Reverse primer: 806R `GGACTACHVGGGTWTCTAAT`

        ITS 1/2 Forward primer: ITS1f `CTTGGTCATTTAGAGGAAGTAA`

        ITS 1/2 Reverse primer: ITS2 `GCTGCGTTCTTCATCGATGC`

        **Note:**  
        1. The sequences (R1.fastq and R2.fastq) from ANL does not contain barcodes or primers! The tag information are stored in the index file (I1.fastq).   
        2. If the mapping file was generated or edited in excel, unwanted invisible characters would be present (you can visualize them in by using `less` or `vi`). To get rid of the characters and make the file recognizable by python, do:
            ```
            ~/Documents/Fan/code/mac2unix.pl MAPPING_FILE.txt > fixed_mapping_file.txt
            ```

    2. SeqFilters need tag file to be like this:   
        ```
        TCCCTTGTCTCC    DC1
        ACGAGACTGATT    DC2
        GCTGTACGGATT    DC3
        ATCACCAGGTGT    DC4
        TGGTCAACGATA    DC5
        ```

        1. You can parse the Argonne file into above format:
            ```
            python ~/Documents/Fan/code/MiSeq_rdptool_map_parser.py ANL_MAPPING_FILE.txt > TAG_FILE.tag
            ```

        2. ANL tag sequences need to be reverse compilmented. It's much easier to reverse compliment the parsed tag file than the index file (XXX_I1.fastq) 
            ```
            python ~/Documents/Fan/code/revcomp_rdp_format.py 16S_tag.txt > 16S_tag_rev.txt
            ```
        
        3. Then run SeqFilters to parse the I1.fastq to bin seq id into individual sample directories.       
            ```
            java -jar $SeqFilters --seq-file original/Undetermined_S0_L001_I1_001.fastq.gz --tag-file 16S_tag_rev.txt --outdir initial_process_Index_rev
            ```

            Note: to make sure tags were binning as expected, the quality of the tag could be set as 0 to begin with `--min-qual 0`   


3. Optional: determine sequence per base stats using usearch:    
        ```
        for i in *.fastq; do ~/usearch70 -fastq_stats $i -log "$i"_stats.log; done
        ```

3. **Chimera removal**       
    1. Why choose Usearch over other?    
        See [here](https://rdp.cme.msu.edu/tutorials/workflows/16S_supervised_flow.html)

    2. For reference mode, why use RDP training sets instead of greengene or silva?   
        See [here](http://www.drive5.com/usearch/manual/uchime_ref.html)

    3. Check [here](http://drive5.com/usearch/) for new version of Usearch. Check [here](http://sourceforge.net/projects/rdp-classifier/files/RDP_Classifier_TrainingData/) for new version of RDP training sets.     

    4. Chimera removal:
        1. Check for chimeras de novo first:
            1. Why?   
                Any chimera generated from unknown organisms that are not in databases would not be eliminated via reference mode.   
  
            2. Use usearch/uparse to quality filter the binned pair-ended (full-coverage) fastq files. For filter parameter and trimming variations and details, see [here](http://drive5.com/usearch/manual/fastq_choose_filter.html)
                ```
                for i in *.fastq; do ~/usearch70 -fastq_filter $i -fastq_maxee 0.5 -fastaout ../../uparsed/quality_filtered/"$i"_maxee_0.5.fasta; done
                ```

            3. Dereplicate reads, determine cluster sizes:
                ```
                for i in *_0.5.fasta; do ~/usearch70 -derep_fulllength $i -output ../derep/"$i"_unique.fasta -sizeout; done
                ```

                *Note:* you could use `-minsize 2` to get rid of singletons at this step. But you still need to sort clusters by size. Might as well get rid of singletons during next step. 


            4. Sort by size to remove singletons:
                ```
                for i in *_unique.fasta; do ~/usearch70 -sortbysize $i -output ../sorted/"$i"_sorted.fa -minsize 2; done
                ```

            4. Use cluster_otus to get rid of chimeras. So I don't like to cluster before I can confirm all of the chimeras are removed... so i clustered my ITS at 0. Also, don't use `-otus`.  
                ```
                for i in *.fa; do ~/usearch70 -cluster_otus $i -otuid 0.985 -fastaout ../4_cluster_otus_0.985/all_headers/"$i"_all_headers.fa -otus ../4_cluster_otus_0.985/otus/"$i"_otus.fa; done                
                ```

            5. get rid of chimera clusters
                ```
                for i in *_header.fasta; do python ~/Documents/Fan/code/usearch_denovo_chim_remover.py $i ../chimera_removed/"$i"_good.fa; done
                ```

    4. Check for chimeras on each binned fasta file with reference dataset:   
        ```
        for i in *_otus1.fa; do ~/usearch70 -uchime_ref $i -db ~/Documents/Databases/RDPClassifier_16S_trainsetNo10_rawtrainingdata/trainset10_082014_rmdup.fasta -uchimeout ../../5_uchime_ref/stats/"$i".uchime -strand plus -selfid -mindiv 1.5 -mindiffs 5 -chimeras ../../5_uchime_ref/chimeras/"$i"_chimera.fa -nonchimeras ../../5_uchime_ref/good_otus/"$i"_good.fa; done
        ```
        
        ```
        for i in *_good.fa; do ~/usearch70 -uchime_ref $i -db ~/Documents/Databases/fungalits_warcup_trainingdata1/Warcup.fungalITS.fasta -uchimeout ../uchime_ref/stats/$i.uchime -strand plus -selfid -mindiv 1.5 -mindiffs 5 -chimeras ../uchime_ref/chimeras/"$i"_chimera.fa -nonchimeras ../uchime_ref/good/"$i"_ref_good.fa; done
        ```
 
        1. Why not check chimeras on the assembled paired-end file?    
            Free Usearch is 32-bit. The big assembled file will cause Usearch to crash for out of memory. The NoTag.fasta may be too large for Usearch as well. Don't be surprised if there is nothing in NoTag uchime outputs. Since, the NoTag files is only used early on to quantify sequence outputs, I usually don't brother to process it any more at this step. 

        2. -mindiv, -mindiffs    
            These parameters are adapted from the old [Uchime](http://www.drive5.com/usearch/manual/UCHIME_score.html). 

        3. The number of chimera sequences and good sequences don't add up?    
            Check your XXX.uchime output. Use:    
            ```
            grep -cw "?" XXX.uchime
            ```
          
            **Note:** The number of chimera, good sequence, and "?" should add up. "?" are sequences that Usearch couldn't classify it as either chimera or good sequence. This usually happens with default parameter. But it shouldn't be happening with `-mindiv 1.5 -mindiffs 5`. 

        4. To check if all files chimera number and good sequence number summs up, in directory `5_uchime_ref`:   
            ```
            grep -c "@M0" /PATH/TO/initial_process_index/binned_assem_250-280/*.fastq > /PATH/TO/initial_process_index/number_reads_assem.txt
            grep -c ">" chimeras/*.fa > number_chimera.txt
            grep -c ">" good_otus/*.fa > number_good_otus.txt
            python ~/Documents/Fan/code/check_chimera_numbers.py number_good_reads.txt number_chimera.txt ../binned_assem/number_16S_assem.txt 
            ```

1. RDP unsupervised analysis: Classifier. group samples into their own groups, ie. cobs for cobs, spruce for spruce.
    ```
    java -Xmx4g -jar ~/RDPTools/classifier.jar classify -g fungalits_warcup -c 0.5 -f fixrank -o Spruce_2013_ITS_classified_0.5.txt -h Spruce_2013_ITS_hier.txt *.fa
    ```

    ```
    java -Xmx4g -jar ~/RDPTools/classifier.jar classify -g fungalits_warcup -c 0.5 -f filterbyconf -o Spruce_2013_ITS_classified_0.5_filtered_rank.txt all_otus.fa 
    ```

Mapping back:
```
for i in *_0.5.fasta; do ~/usearch70 -usearch_global $i -db ../6_consolidate_otus/all_otus.fa -strand plus -id 0.97 -uc ../7_map_uc/"$i"_map.uc; done
```

Add sample name to map.uc
```
for i in *.uc; do python ~/Documents/Fan/code/usearch_map_uc_parser.py $i > ../map_uc_sample/"$i".sample; done
```
When mapping map.uc back to the sequence, I think the singletons are also included when mapping. considering the whole point of removing singletons because they are errorness. Should get rid of the singletons from the very beginning?

For 16S:
```
~/usearch70 -usearch_global ../../16s_test.fasta -db uparse_test_otu_clust_0.97_otusn.fasta -strand plus -id 0.97 -matched 16s_test_matched.fa -uc 16s_test_readmap.uc
```

java -Xmx4g -jar /Users/metagenomics/RDPTools/Clustering.jar derep --unaligned -o /Users/metagenomics/Documents/2013_ITS_fy/uparsed/6_consolidate_otus/rdp_derep/all_seqs_derep.fasta /Users/metagenomics/Documents/2013_ITS_fy/uparsed/6_consolidate_otus/rdp_derep/all_seqs.ids /Users/metagenomics/Documents/2013_ITS_fy/uparsed/6_consolidate_otus/rdp_derep/all_seqs.samples /Users/metagenomics/Documents/2013_ITS_fy/uparsed/6_consolidate_otus/all_maxee_0.5.fa


increase the break number to avoid new false chimeras
~/usearch70 -cluster_otus cat_otu_good_derep_sorted.fa -otuid 0.985 -uparse_break -100.0 -otus all_otus1.fa -fastaout all_header_otus1.fa

for i in *.fasta; do ~/usearch70 -usearch_global $i -db ../6_consolidate_otus/all_otusn.fa -strand plus -id 0.985 -uc ../7_map_uc/map_uc/"$"_map.uc; done

16S:
for i in *.fasta; do ~/usearch70 -usearch_global $i -db ../5_uchime_ref/good_otus_renamed/"$i"_unique.fasta_sorted.fa_otus1.fa_good.fa_otus.fa -strand plus -id 0.985 -uc ../6_map_reads/uc/"$i"_map.uc -matched ../6_map_reads/seqs/"$i"_matched.fa; done
