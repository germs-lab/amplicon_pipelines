# renames sample sequence files
# renames sequences in each file
# writes out sample file name map, sequence name map, and new sequences
import os
import sys
from Bio import SeqIO

def rename_seqs(seq_fa, file_index):
	d = {}
	n = 0
	for records in SeqIO.parse(open(seq_fa, 'rU'), "fasta"):
		n = n + 1
		records.id = 'S_' + str(file_index) + '|' + str(n)
#		records.name = records.id
#		records.description = records.id
		d[records.id] = [records.name, records.seq]
	return d 
		
f = sys.argv[3:]

filename_map = open(sys.argv[1], "w")
seqname_map = open(sys.argv[2], 'w')
for (i, filenames) in enumerate(f):
	filename_map.write("%s\t%s\n" % (filenames, "S_"+str(i)))
	new = rename_seqs(filenames, i)
	for item in new:
		seqname_map.write("%s\t%s\n" % (item, new[item][0]))
		print ">" + item
		print new[item][1]	
