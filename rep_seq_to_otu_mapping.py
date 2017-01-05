## input file: anything resembles /Users/metagenomics/Documents/Fan/scratch/xander_701/Asp/nucl_cdhit.fasta.clstr

import sys
import os
import re

f = open(sys.argv[1], 'rU')

for n, line in enumerate(f):
	line = line.rstrip()
	if line.startswith(">Cluster"):
		string = re.split(" |\n", line)
		id = "OTU_" + string[1]
	if line.endswith("*"):
		lexeme = re.split("\t| |>|\...", line)
		contig = lexeme[3]
		print '%s\t%s' % (id, contig)

