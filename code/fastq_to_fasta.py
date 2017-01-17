import os
import sys
from Bio import SeqIO

f = open(sys.argv[1], 'rU')
out = open(sys.argv[2], 'w')
for records in SeqIO.parse(f, 'fastq'):
	SeqIO.write(records, out, 'fasta')
