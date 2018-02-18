import sys
import os
import re
from itertools import groupby

def clstr_iter(cdhit_clstr):
        f = open(cdhit_clstr)
        citer = (x[1] for x in groupby(f, lambda line: line[0] == ">"))
        for cluster in citer:
                seq = {}
                for line in citer.next():
#                       if line.startswith("0"):
                        if "*" in line:
                                string = re.split("\t| |>|\.|\||;", line)
                                cluster = string[3]
                        else: 
                                string = re.split("\t| |>|\.|\|", line)
                                sample = string[3]
                                seq_id = string[4]
                                if sample not in seq:
                                        seq[sample] = [seq_id]
                                else:
                                        seq[sample].append(seq_id)
                yield cluster, seq

clstr = sys.argv[1]
d = dict(clstr_iter(clstr))
for item in d:
        for s in d[item]:
                print "%s\t%s\t%s" % (item, s, len(d[item][s]))
