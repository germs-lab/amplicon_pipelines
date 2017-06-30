DIR= /mnt/research/germs/ANL_16s_may242017_R161209-1
ORI= /mnt/research/germs/ANL_16s_may242017_R161209-1/original
SUBPROJECT= jin fan maurilia

CODE= /mnt/home/yangfan1/repos/amplicon_pipelines/code
RDP= /mnt/research/rdp/public
CHIMERA_DB= /mnt/home/yangfan1/databases/current_Bacteria_unaligned.fa

VSEARCH= /mnt/research/germs/softwares/vsearch-2.4.3-linux-x86_64/bin/vsearch

## assemble paired-ends. The below parameters work well with bacterial 16S. 
OVERLAP= 10## minimal number of overlapped bases required for pair-end assembling. Not so critical if you set the length parameters (see below)
MINLEN= 250#16s: "250" ## minimal length of the assembled sequence
MAXLEN= 280#16s: "280" ## maximum length of the assembled sequence
Q= 25## minimal read quality score.

all: sample_names.txt 1_rdp_pandaseq assemble 2_quality_check quality chimera_prep fq_to_fa combine_derep_sort chimera_denovo chimera_ref remapping 3_cdhit_clustering renaming clustering otu_table taxa_table

assemblage: sample_names.txt 1_rdp_pandaseq assemble
quality_check: 2_quality_check quality chimera_prep fq_to_fa combine_derep_sort chimera_denovo chimera_ref remapping
cdhit_clustering: 3_cdhit_clustering renaming clustering otu_table taxa_table

.PHONY: all cleaet 

# 1. assemble pair-ended readsi using RDP pandaseq.
1_rdp_pandaseq:
	mkdir 1_rdp_pandaseq

assemble:
	cd $(DIR)/1_rdp_pandaseq && \
	$(RDP)/RDP_misc_tools/pandaseq/pandaseq -N -o $(OVERLAP) -e $(Q) -F -d rbfkms -l $(MINLEN) -L $(MAXLEN) -f $(ORI)/*_R1_*.fastq.gz -r $(ORI)/*_R2_*.fastq.gz 1> assembled_reads_"$(MINLEN)"-"$(MAXLEN)".fastq 2> assembled_reads_"$(MINLEN)"-"$(MAXLEN)".stats

# 2. check sequence quality.
2_quality_check:
	mkdir 2_quality_check 

quality:
	cd $(DIR)/1_rdp_pandaseq && \
	java -jar $(RDP)/RDPTools/SeqFilters.jar -Q $(Q) -s assembled_reads_"$(MINLEN)"-"$(MAXLEN)".fastq  -o $(DIR)/2_quality_check -O assembled_reads_"$(MINLEN)"-"$(MAXLEN)".q25

chimera_prep:
	cd $(DIR)/2_quality_check && \
	mv assembled_reads_"$(MINLEN)"-"$(MAXLEN)".q25/NoTag/NoTag_trimmed.fastq ../assembled_reads_"$(MINLEN)"-"$(MAXLEN)".q25.fq

fq_to_fa:
	cd $(DIR)/2_quality_check && \
	python $(CODE)/fastq_to_fasta.py assembled_reads_"$(MINLEN)"-"$(MAXLEN)".q25.fq assembled_reads_"$(MINLEN)"-"$(MAXLEN)".q25.fa

combine_derep_sort:
	cd $(DIR)/2_quality_check/fasta_q25 && \
	cat *.fa >> $(DIR)/2_quality_check/chimera_removal/all_combined_q25.fa
	cd $(DIR)/2_quality_check/chimera_removal && \
	$(VSEARCH) --derep_fulllength all_combined_q25.fa --output all_combined_q25_unique_sort_min2.fa --sizeout --minuniquesize 2

chimera_denovo:
	cd $(DIR)/2_quality_check/chimera_removal && \
	$(VSEARCH) --uchime_denovo all_combined_q25_unique_sort_min2.fa --chimeras all_combined_q25_unique_sort_min2_denovo.chimera --nonchimeras all_combined_q25_unique_sort_min2_denovo.good

## submitted: 256G mem, used 2 hours for 420773 unique sequences.
chimera_ref:
	cd $(DIR)/2_quality_check/chimera_removal && \
	$(VSEARCH) --uchime_ref all_combined_q25_unique_sort_min2_denovo.good --nonchimeras all_combined_q25_unique_sort_min2_denovo_ref.good --db $(CHIMERA_DB)

## submitted: 256G mem, used 2 hours for remapping.
remapping:
	cd $(DIR)/2_quality_check/fasta_q25 && \
	for i in *.fa; do \
		echo "$(VSEARCH) --usearch_global $$i --db $(DIR)/2_quality_check/chimera_removal/all_combined_q25_unique_sort_min2_denovo_ref.good --id 0.985 --matched $(DIR)/2_quality_check/final_good_seqs/"$$i"_finalized.fa"; \
	done > $(DIR)/remapping.sh; \
	true && \
	cat $(DIR)/remapping.sh | parallel -j 4

mkdir 2_quality_check

java -jar /mnt/research/rdp/public/RDPTools/SeqFilters.jar -Q 25 -s 1_rdp_pandaseq/assembled_reads_250-280.fastq -o 2_quality_check/ -O assembled_reads_250-280.q25

cd /mnt/research/germs/fan/lapaz_shrimp_16s/2_quality_check/chimera_removal
/mnt/research/germs/softwares/vsearch-2.4.3-linux-x86_64/bin/vsearch --derep_fulllength assembled_reads_250-280.q25/NoTag/trimmed_q25.fa --output  chimera_removal/trimmed_q25_unique.fa --sizeout --minuniquesize 2

cd /mnt/research/germs/fan/lapaz_shrimp_16s/2_quality_check
/mnt/research/germs/softwares/vsearch-2.4.3-linux-x86_64/bin/vsearch --uchime_denovo chimera_removal/trimmed_q25_unique_sort_min2.fa --chimeras chimera_removal/trimmed_q25_unique_sort_min2_denovo.chimera --nonchimeras chimera_removal/trimmed_q25_unique_sort_min2_denovo.good

# submitted: 256G mem, used 2 hours for 420773 unique sequences.
/mnt/research/germs/softwares/vsearch-2.4.3-linux-x86_64/bin/vsearch --uchime_ref chimera_removal/trimmed_q25_unique_sort_min2_denovo.good --nonchimeras chimera_removal/trimmed_q25_unique_sort_min2_denovo_ref.good --db ~/databases/current_Bacteria_unaligned.fa

# submitted: 256G mem, used 2 hours for remapping.
/mnt/research/germs/softwares/vsearch-2.4.3-linux-x86_64/bin/vsearch --usearch_global assembled_reads_250-280.q25/NoTag/trimmed_q25.fa --db chimera_removal/trimmed_q25_unique_sort_min2_denovo_ref.good --id 0.985 --matched all_trimmed_chimed_finalized.fa


mkdir 3_demultiplex

python ~/repos/code/MiSeq_rdptool_map_parser.py original/170410_Mapping_File_CIBNOR_16S_FWD_20170408.txt > 3_demultiplex/tag_file.tag

java -jar /mnt/research/rdp/public/RDPTools/SeqFilters.jar --seq-file original/Undetermined_S0_L001_I1_001.fastq.gz --tag-file 3_demultiplex/tag_file.tag --outdir 3_demultiplex/parse_index

mkdir 3_demultiplex/parse_index/trimmed_tags
mv 3_demultiplex/parse_index/result_dir/*/*_trimmed.fasta 3_demultiplex/parse_index/trimmed_tags/

cd /mnt/research/germs/fan/lapaz_shrimp_16s/3_demultiplex/parse_index/trimmed_tags
python ~/repos/code/bin_reads.py /mnt/research/germs/fan/lapaz_shrimp_16s/2_quality_check/all_trimmed_chimed_finalized.fa

mkdir ../../demultiplexed_finalized
mv *_assem.fastq ../../demultiplexed_finalized/
for i in *.fastq; do mv $i "${i//.fasta_assem.fastq/}"_assem.fa;done

mkdir ../empty_samples
find . -type f -size 0 -exec mv -t ../empty_samples/ {} +


python ~/repos/amplicon_pipelines/code/renaming_seq_w_short_sample_name.py ../../4_cdhit_clustering/renamed_seqs/sample_filename_map.txt ../../4_cdhit_clustering/renamed_seqs/sequence_name_map.txt *_assem.fa > ../../4_cdhit_clustering/renamed_seqs/all_renamed_sequences.fa

cd ../../4_cdhit_clustering/master_otus/
cd-hit-est -i ../renamed_seqs/all_renamed_sequences.fa -o combined_renamed_seqs_cdhit.fasta -c 0.97 -M 200000 -T 16

python ~/repos/amplicon_pipelines/code/cdhit_clstr_to_otu.py combined_renamed_seqs_cdhit.fasta.clstr ../R/cdhit_otu_table_wide.txt

Rscript ~/repos/amplicon_pipelines/code/convert_otu_table_long_to_wide_format.R cdhit_otu_table_long.txt ../R/cdhit_otu_table_wide.txt

java -Xmx24g -jar /mnt/research/rdp/public/RDPTools/classifier.jar classify -c 0.5 -f filterbyconf -o ../R/cdhit_otu_taxa_filterbyconf.txt -h cdhit_otu_taxa_filterbyconf_hierarchy.txt combined_renamed_seqs_cdhit.fasta

python ~/repos/amplicon_pipelines/code/rep_seq_to_otu_mapping.py combined_renamed_seqs_cdhit.fasta.clstr > combined_renamed_seqs_cdhit_rep_seq_to_cluster.map

Rscript ~/repos/amplicon_pipelines/code/renaming_taxa_rep_seq_to_otus.R cdhit_otu_taxa_filterbyconf.txt combined_renamed_seqs_cdhit_rep_seq_to_cluster.map ../R/cdhit_taxa_table_w_repseq.txt
