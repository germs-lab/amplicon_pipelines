#!/bin/sh -e

## Before start:
## Create a folder for sequence processing (see DIR below). 
## Put all raw reads in a folder called `original` nested within DIR.
## update the path and parameters!

## prerequesit:
## python 2.7+, biopython

DIR="/mnt/research/germs/soilcolumn16S2016_processed"
ORI="/mnt/research/germs/soilcolumn16S2016_original"
CODE="/mnt/home/yangfan1/repos/amplicon_pipelines/code"
RDP="/mnt/research/rdp/public"
CHIMERA_DB="/mnt/scratch/yangfan1/databases/current_Bacteria_unaligned.fa"

## to parse out sample names and eliminate the different parts:
## eg. for pair-ended files "1001b_GCGTATAC_ATCGTACG_L001_R1_001.fastq" and "1001b_GCGTATAC_ATCGTACG_L001_R2_001.fastq"
## "_" is the delimiter that breaks the file name into sample, tags, running cell/lane, and read.
## "R1" and "R2" are the only differences between these two files. They suggest these two files are read 1 and read 2 of a pair-end sequence.  
## the main portion of the file names that are the same are (indexed by delimiter) from the beinning through 3 from the right. 
## "_001.fastq" is the same portion after "R1" and "R2"
FN_DELIM="_"   
FN_REV_INDEX="3"
FN_END="_001.fastq.gz"  

## assemble paired-ends. The below parameters work well with bacterial 16S. 
OVERLAP="10" ## minimal number of overlapped bases required for pair-end assembling. Not so critical if you set the length parameters (see below)
Q="25" ## minimal read quality score.
MINLEN="250" #16s: "250" ## minimal length of the assembled sequence
MAXLEN="280" #16s: "280" ## maximum length of the assembled sequence

########################################################################
### DO NOT change anything below unless you know what you are doing! ###
########################################################################
# 1. create a list of sample names. find the sample name shared between R1 and R2.
cd $ORI
ls *_R*.fastq* > $DIR/raw_seq_list.txt

cd $DIR
rev raw_seq_list.txt | cut -d $FN_DELIM -f "$FN_REV_INDEX"- | rev | sort | uniq > sample_names.txt

## check:
num_files=`wc -l raw_seq_list.txt | grep -o "[0-9]\+"`
num_samples=`wc -l sample_names.txt | grep -o "[0-9]\+"`

if [ $num_samples -eq $((num_files / 2)) ]
then
        echo "OK: sample names parsed"
else
        echo "Number of pair-ended sequence files does not match the number of sample names. Please check"
	exit
fi

# 2. assemble pair-ended readsi using RDP pandaseq.
cd $DIR
mkdir $DIR/1_rdp_pandaseq
cd 1_rdp_pandaseq
mkdir assembled stats

while read i 
do 
	$RDP/RDP_misc_tools/pandaseq/pandaseq -N -o $OVERLAP -e $Q -F -d rbfkms -l $MINLEN -L $MAXLEN -f $DIR/original/"$i""$FN_DELIM"R1"$FN_END" -r  $DIR/original/"$i""$FN_DELIM"R2"$FN_END" 1> assembled/"$i"_150-263.fastq 2> stats/"$i"_assembled_stats.txt
done < $DIR/sample_names.txt 

wait

num_assembled=`ls assembled/*.fastq | wc -l | grep -o "[0-9]\+"`
if [ $num_assembled -eq $num_samples ]
then 
	echo "OK: assembled"
else
	echo "Number of samples assembled does not match the number of samples. Please check"
fi

# 3. check sequence quality.
cd $DIR
mkdir $DIR/2_quality_check
cd 2_quality_check/
mkdir temp fastq_q25 fasta_q25 chimera_removal final_good_seqs

## checking sequence quality using seqfilters
cd $DIR/1_rdp_pandaseq/assembled
for i in *.fastq
do 
	java -jar $RDP/RDPTools/SeqFilters.jar -Q $Q -s $i -o $DIR/2_quality_check/temp/ -O $i.q25
done

wait

## get quality filtered sequences and delete the temp folder
cd $DIR/2_quality_check/temp
for i in *.q25 
do 
	mv $i/NoTag/NoTag_trimmed.fastq ../fastq_q25/${i//.fastq.q25/.q25}.fq
done

wait

rm -r $DIR/2_quality_check/temp
# convert fastq files to fasta files to be used for chimera checking
cd $DIR/2_quality_check/fastq_q25 
for i in *.fq 
do 
	python $CODE/fastq_to_fasta.py $i ../fasta_q25/${i//.fq/}.fa
done

wait

###########################################################################
## if you only have usearch 32 bit (free version), use below code      ####
##########################################################################
#### check for chimeras using uclust, per file then combine
###cd $DIR/2_quality_check
###cd $DIR/2_quality_check/fasta_q25
###
###bash $CODE/chimera_removal_pipeline.sh

##############################################################
### if you do have usearch 64 bit, use below code         ####
### This is also the most time consuming step             ####
##############################################################
## check for chimeras using uclust 64 bit version
cd $DIR/2_quality_check/fasta_q25
### combine all good quality sequences
cat *.fa >> $DIR/2_quality_check/chimera_removal/all_combined_q25.fa

wait

cd $DIR/2_quality_check/chimera_removal
## derep all sequences
$RDP/thirdParty/usearch8.1.1831_i86linux64 -derep_fulllength all_combined_q25.fa -fastaout all_combined_q25_unique.fa -sizeout
wait
## sort by abundance and exclude singletons
$RDP/thirdParty/usearch8.1.1831_i86linux64 -sortbysize all_combined_q25_unique.fa -fastaout all_combined_q25_sorted.fa -minsize 2
wait
## de novo chimera check using -cluster_otus option. `-id` indicates radius, therefore for 0.97 similarity to centroid, one should use 0.985. It takes ~7 hours for 2 million unique (no singletons) reads (256 G of memory).    
$RDP/thirdParty/usearch8.1.1831_i86linux64 -cluster_otus all_combined_q25_sorted.fa -id 0.985 -otus all_combined_q25_chim_denovo.fa
wait
## reference based chimera removal using rdp full set. It takes ~17 hours (256 G of memory). 
$RDP/thirdParty/usearch8.1.1831_i86linux64 -uchime_ref all_combined_q25_chim_denovo.fa -db $CHIMERA_DB -strand plus -chimeras all_combined_q25_chim_ref.chimeras -nonchimeras all_combined_q25_chim_ref.fa
wait

### mapping quality trimmed sequence back onto chimera checked ones
cd $DIR/2_quality_check/fastq_q25
for i in *.fq
do 
	$RDP/thirdParty/usearch8.1.1831_i86linux64 -usearch_global $i -db ../chimera_removal/all_combined_q25_chim_ref.fa -strand plus -id 0.985 -matched ../final_good_seqs/"${i//.fq/}"_finalized.fa 
done 

wait

# 4. clustering using cdhit. From here and on, it takes 2.5 hours (cores=4, ppn=4, mem=256G).
cd $DIR
mkdir $DIR/3_cdhit_clustering
cd 3_cdhit_clustering
mkdir renamed_seqs master_otus R
## renameing sequences, writing out mapping files, and one sequence files
cd $DIR/2_quality_check/final_good_seqs
python $CODE/renaming_seq_w_short_sample_name.py $DIR/3_cdhit_clustering/renamed_seqs/sample_filename_map.txt $DIR/3_cdhit_clustering/renamed_seqs/sequence_name_map.txt *_finalized.fa > $DIR/3_cdhit_clustering/renamed_seqs/all_renamed_sequences.fa

wait

## clustering
cd $DIR/3_cdhit_clustering/master_otus
cd-hit-est -i ../renamed_seqs/all_renamed_sequences.fa -o combined_renamed_seqs_cdhit.fasta -c 0.97 -M 200000 -T 16

wait

## make otu table in long format
python $CODE/cdhit_clstr_to_otu.py combined_renamed_seqs_cdhit.fasta.clstr > cdhit_otu_table_long.txt

wait

## convert otu table to wide format (otus as rows, samples as columns)
Rscript $CODE/convert_otu_table_long_to_wide_format.R cdhit_otu_table_long.txt ../R/cdhit_otu_table_wide.txt

# 5. identify otu taxonomy
java -Xmx24g -jar $RDP/RDPTools/classifier.jar classify -c 0.5 -f filterbyconf -o cdhit_otu_taxa_filterbyconf.txt -h cdhit_otu_taxa_filterbyconf_hierarchy.txt combined_renamed_seqs_cdhit.fasta

# 6. map otus to repseqs for rdp classified filterbyconf taxa table
python $CODE/rep_seq_to_otu_mapping.py combined_renamed_seqs_cdhit.fasta.clstr > combined_renamed_seqs_cdhit_rep_seq_to_cluster.map
Rscript $CODE/renaming_taxa_rep_seq_to_otus.R cdhit_otu_taxa_filterbyconf.txt combined_renamed_seqs_cdhit_rep_seq_to_cluster.map ../R/cdhit_taxa_table_w_repseq.txt

