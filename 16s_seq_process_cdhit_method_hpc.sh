#!/bin/sh -e

## Before start:
## Create a folder for sequence processing (see DIR below). 
## Put all raw reads in a folder called `original` nested within DIR.

## prerequesit:
## python 2.7+, biopython

DIR="/mnt/scratch/yangfan1/sasha_16s"
CODE="/mnt/home/yangfan1/repos/amplicon_pipelines"
RDP="/mnt/research/rdp/public"
CHIMERA_DB="/mnt/scratch/yangfan1/databases/current_Bacteria_unaligned.fa"

## to parse out sample names
FN_DELIM="_"
FN_END="_001.fastq"
FN_REV_INDEX="3"

## assemble paired-ends
OVERLAP="10"
Q="25"
MINLEN="250"
MAXLEN="280"

module load Java/1.7.0_51
module load CDHIT/4.6.1
module load R/2.15.1

## 1. create a list of sample names. find the sample name shared between R1 and R2.
#cd $DIR/original
#ls *.fastq* > ../raw_seq_list.txt
#
#cd $DIR
#rev raw_seq_list.txt | cut -d $FN_DELIM -f "$FN_REV_INDEX"- | rev | sort | uniq > sample_names.txt
#
### check:
#num_files=`wc -l raw_seq_list.txt | grep -o "[0-9]\+"`
#num_samples=`wc -l sample_names.txt | grep -o "[0-9]\+"`
#
#if [ $num_samples -eq $((num_files / 2)) ]
#then
#        echo "OK: sample names parsed"
#else
#        echo "Number of pair-ended sequence files does not match the number of sample names. Please check"
#fi
#
## 2. assemble pair-ended readsi using RDP pandaseq.
#cd $DIR
#mkdir $DIR/1_rdp_pandaseq
#cd 1_rdp_pandaseq
#mkdir assembled stats
#
#while read i 
#do 
#	$RDP/RDP_misc_tools/pandaseq/pandaseq -N -o $OVERLAP -e $Q -F -d rbfkms -l $MINLEN -L $MAXLEN -f $DIR/original/"$i""$FN_DELIM"R1"$FN_END" -r  $DIR/original/"$i""$FN_DELIM"R2"$FN_END" 1> assembled/"$i"_250-280.fastq 2> stats/"$i"_assembled_stats.txt
#done < $DIR/sample_names.txt
#
#num_assembled=`ls assembled/*.fastq | wc -l | grep -o "[0-9]\+"`
#if [ $num_assembled -eq $num_samples ]
#then 
#	echo "OK: assembled"
#else
#	echo "Number of samples assembled does not match the number of samples. Please check"
#fi
#
## 3. check sequence quality.
#cd $DIR
#mkdir $DIR/2_quality_check
#cd 2_quality_check/
#mkdir temp fastq_q25 fasta_q25 chimera_removal final_good_seqs
#
### checking sequence quality using seqfilters
#cd $DIR/1_rdp_pandaseq/assembled
#for i in *.fastq
#do 
#	java -jar $RDP/RDPTools/SeqFilters.jar -Q $Q -s $i -o $DIR/2_quality_check/temp/ -O $i.q25
#done
### get quality filtered sequences and delete the temp folder
#cd $DIR/2_quality_check/temp
#for i in *.q25 
#do 
#	mv $i/NoTag/NoTag_trimmed.fastq ../fastq_q25/${i//.fastq.q25/.q25}.fq
#done
##rm -r $DIR/2_quality_check/temp
## convert fastq files to fasta files to be used for chimera checking
cd $DIR/2_quality_check/fastq_q25 
for i in *.fq 
do 
	python $CODE/fastq_to_fasta.py $i ../fasta_q25/${i//.fq/}.fa
done
## check for chimeras using uclust 64 bit version
cd ../fasta_q25
### combine all good quality sequences
cat *.fa >> ../chimera_removal/all_combined_q25.fa

cd ../chimera_removal
### derep all sequences
$RDP/thirdParty/usearch8.1.1831_i86linux64 -derep_fulllength all_combined_q25.fa -fastaout all_combined_q25_unique.fa -sizeout
### sort by abundance and exclude singletons
$RDP/thirdParty/usearch8.1.1831_i86linux64 -sortbysize all_combined_q25_unique.fa -fastaout all_combined_q25_sorted.fa -minsize 2
### de novo chimera check using -cluster_otus option. `-id` indicates radius, therefore for 0.97 similarity to centroid, one should use 0.985. 
$RDP/thirdParty/usearch8.1.1831_i86linux64 -cluster_otus all_combined_q25_sorted.fa -id 0.985 -otus all_combined_q25_chim_denovo.fa
### reference based chimera removal using rdp full set
$RDP/thirdParty/usearch8.1.1831_i86linux64 -uchime_ref all_combined_q25_chim_denovo.fa -db $CHIMERA_DB -strand plus -chimeras all_combined_q25_chim_denovo_ref_fullrdp.chimeras -nonchimeras all_combined_q25_chim_denovo_ref_fullrdp_good.fa

### mapping quality trimmed sequence back onto chimera checked ones
cd ../fastq_q25
for i in *.fq
do 
	$RDP/thirdParty/usearch8.1.1831_i86linux64 -usearch_global $i -db ../chimera_removal/all_combined_q25_chim_denovo_ref_fullrdp_good.fa -strand plus -id 0.985 -matched ../final_good_seqs/"${i//.fq/}"_finalized.fa
done

# 4. clustering using cdhit
cd $DIR
mkdir $DIR/3_cdhit_clustering
cd 3_cdhit_clustering
mkdir renamed_seqs master_otus R
## renameing sequences, writing out mapping files, and one sequence files
cd $DIR/2_quality_check/final_good_seqs
python $CODE/renaming_seq_w_short_sample_name.py $DIR/3_cdhit_clustering/renamed_seqs/sample_filename_map.txt $DIR/3_cdhit_clustering/renamed_seqs/sequence_name_map.txt *_finalized.fa > $DIR/3_cdhit_clustering/renamed_seqs/all_renamed_sequences.fa

## clustering
cd $DIR/3_cdhit_clustering/master_otus
cd-hit-est -i ../renamed_seqs/all_renamed_sequences.fa -o combined_renamed_seqs_cdhit.fasta -c 0.97 -M 8000 -T 3

## make otu table in long format
python $CODE/cdhit_clstr_to_otu.py combined_renamed_seqs_cdhit.fasta.clstr > cdhit_otu_table_long.txt

## convert otu table to wide format (otus as rows, samples as columns)
Rscript $CODE/convert_otu_table_long_to_wide_format.R cdhit_otu_table_long.txt ../R/cdhit_otu_table_wide.txt

# 5. identify otu taxonomy
java -Xmx24g -jar $RDP/RDPTools/classifier.jar classify -c 0.5 -f filterbyconf -o cdhit_otu_taxa_filterbyconf.txt -h cdhit_otu_taxa_filterbyconf_hierarchy.txt combined_renamed_seqs_cdhit.fasta

#i 6. map otus to repseqs for rdp classified filterbyconf taxa table
python $CODE/rep_seq_to_otu_mapping.py combined_renamed_seqs_cdhit.fasta.clstr > combined_renamed_seqs_cdhit_rep_seq_to_cluster.map
Rscript $CODE/renaming_taxa_rep_seq_to_otus.R cdhit_otu_taxa_filterbyconf.txt combined_renamed_seqs_cdhit_rep_seq_to_cluster.map ../R/cdhit_taxa_table_w_repseq.txt

