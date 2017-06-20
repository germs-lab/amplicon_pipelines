# cd /mnt/research/germs/soilcolumn16S2016_processed/pandaseq_test/assembled
# cat *.fastq > ../all_overlap10.fastq

import sys
import os
from Bio import SeqIO

def get_seqid(stats):
	l = []
	for lines in stats:
		lines = lines.strip()
		lexemes = lines.split('\t')
		if len(lexemes) == 12:
			seq_id = lexemes[3]
			seq_len = int(lexemes[5])
			avg_Q = int(lexemes[-4])
			overlap = int(lexemes[-3])	
			new_seq_id = seq_id + ", len: " + str(seq_len)
			if avg_Q >= 25 and seq_len < 250 or seq_len > 280: 
				l.append(seq_id)
	return l

rdp_stats=sys.argv[2:]
d = {}
for i in rdp_stats:
	f = open(i)
	name = i.split("/")[-1]	
	ids = get_seqid(f)
	d[name] = ids

seq = {}
for records in SeqIO.parse(open(sys.argv[1]), 'fastq'):
	seq[records.id] = records.seq

for sample in d:
	for item in d[sample]:
		if item in seq.keys():
			print ">" + sample + "::" + item + "\n" + seq[item]
