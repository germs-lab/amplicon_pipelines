U="/mnt/research/rdp/public/thirdParty/usearch8.1.1831_i86linux64"
CHIMERA_DB="/mnt/scratch/yangfan1/databases/current_Bacteria_unaligned.fa"

# dereplicating reads per file
mkdir ../chimera_removal/unique
for i in *.q25.fa
do
	echo "$U -derep_fulllength $i -fastaout ../chimera_removal/unique/"${i//.fa/}"_unique.fa -sizeout"
done >> get_unique_seqs_per_file.sh

cat get_unique_seqs_per_file.sh | parallel

# sorting unique reads per file
mkdir ../chimera_removal/sorted
cd ../chimera_removal/unique
for i in *_unique.fa
do
	echo "$U -sortbysize $i -fastaout ../sorted/"${i//.fa/}"_sorted.fa -minsize 2"
done >> sort_unique_min2_per_file.sh

cat sort_unique_min2_per_file.sh | parallel

# de novo chimera check per file
mkdir ../denovo
cd ../sorted
for i in *_sorted.fa
do
	echo "$U -cluster_otus $i -id 0.985 -otus ../denovo/"${i//.fa/}"_denovo.fa -threads 4"
done >> chimera_denovo_per_file.sh

cat chimera_denovo_per_file.sh | parallel

# reference chimera check per file (don't use parallel. this step takes time and resource)
# usearch v8.1.1831_i86linux64, 132Gb RAM, 28 cores (on dev 16)
mkdir ../ref
cd ../denovo
for i in *_denovo.fa
do
	$U -uchime_ref $i -db $CHIMERA_DB -strand plus -nonchimeras ../ref/"${i//.fa/}"_ref.fa
done 

# consolidating all good otus into 1 file
mkdir ../combined_no_chimera
cd ../combined_no_chimera
cat ../ref/*_ref.fa > combined.fa
$U -derep_fulllength combined.fa -fastaout combined_unique.fa -sizeout
$U -sortbysize combined_unique.fa -fastaout combined_sorted.fa -minsize 1
$U -cluster_otus combined_sorted.fa -id 0.985 -uparse_break -100.0 -otus combined_good.fa

