

mkdir 1_rdp_pandaseq

#/mnt/research/rdp/public/RDP_misc_tools/pandaseq/pandaseq -N -o 10 -e 25 -F -d rbfkms -f original/Undetermined_S0_L001_R1_001.fastq.gz -r original/Undetermined_S0_L001_R2_001.fastq.gz 1> assembled_reads_o10.fastq 2> assembled_reads_o10.stats

/mnt/research/rdp/public/RDP_misc_tools/pandaseq/pandaseq -N -o 10 -e 25 -F -d rbfkms -l 250 -L 280 -f original/Undetermined_S0_L001_R1_001.fastq.gz -r original/Undetermined_S0_L001_R2_001.fastq.gz 1> assembled_reads_250-280.fastq 2> assembled_reads_250-280.stats

mkdir 2_quality_check

java -jar /mnt/research/rdp/public/RDPTools/SeqFilters.jar -Q 25 -s 1_rdp_pandaseq/assembled_reads_250-280.fastq -o 2_quality_check/ -O assembled_reads_250-280.q25

mkdir 3_demultiplex

python ~/repos/code/MiSeq_rdptool_map_parser.py original/170410_Mapping_File_CIBNOR_16S_FWD_20170408.txt > 3_demultiplex/tag_file.tag

java -jar /mnt/research/rdp/public/RDPTools/SeqFilters.jar --seq-file original/Undetermined_S0_L001_I1_001.fastq.gz --tag-file 3_demultiplex/tag_file.tag --outdir 3_demultiplex/parse_index

mkdir 3_demultiplex/parse_index/trimmed_tags
 mv 3_demultiplex/parse_index/result_dir/*/*_trimmed.fasta 3_demultiplex/parse_index/trimmed_tags/

cd /mnt/research/germs/fan/lapaz_shrimp_16s/2_quality_check/chimera_removal
/mnt/research/germs/softwares/vsearch-2.4.3-linux-x86_64/bin/vsearch --derep_fulllength assembled_reads_250-280.q25/NoTag/trimmed_q25.fa --output  chimera_removal/trimmed_q25_unique.fa --sizeout --minuniquesize 2

cd /mnt/research/germs/fan/lapaz_shrimp_16s/2_quality_check
/mnt/research/germs/softwares/vsearch-2.4.3-linux-x86_64/bin/vsearch --uchime_denovo chimera_removal/trimmed_q25_unique_sort_min2.fa --chimeras chimera_removal/trimmed_q25_unique_sort_min2_denovo.chimera --nonchimeras chimera_removal/trimmed_q25_unique_sort_min2_denovo.good

# submitted: 256G mem, used 2 hours for 420773 unique sequences.
/mnt/research/germs/softwares/vsearch-2.4.3-linux-x86_64/bin/vsearch --uchime_ref chimera_removal/trimmed_q25_unique_sort_min2_denovo.good --nonchimeras chimera_removal/trimmed_q25_unique_sort_min2_denovo_ref.good --db ~/databases/current_Bacteria_unaligned.fa

/mnt/research/germs/softwares/vsearch-2.4.3-linux-x86_64/bin/vsearch --usearch_global assembled_reads_250-280.q25/NoTag/trimmed_q25.fa --db chimera_removal/trimmed_q25_unique_sort_min2_denovo_ref.good --id 0.985 --matched all_trimmed_chimed_finalized.fa
