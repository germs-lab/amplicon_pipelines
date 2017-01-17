import sys
import os
import numpy

l = []
for lines in open(sys.argv[1], 'rU'):
	lines = lines.strip()
	lexemes = lines.split('\t')
	if len(lexemes) == 12:
		seq_id = lexemes[3]
		seq_len = int(lexemes[5])
		avg_Q = int(lexemes[-4])
		overlap = int(lexemes[-3])	
		if avg_Q >= 25 and overlap >= 10: #and seq_len>=250 and seq_len<=280: 
#			print seq_id
			l.append(seq_len)
	#		if seq_len == min(l):
	#			print lines
	#		if overlap == max(s_l):
	#			s_ol.append(seq_len)
#		elif seq_len >= 100 and avg_Q >= 27 and overlap > 40:
#			l.append(overlap)
#			if overlap == max(l):
#				ol.append(seq_len)
#print "There are %s assembled reads that have over 80b overlaps, with a Q >= 25." % len(l)
print "The shortest overlap is: %s" % min(l)
print "The longest overlap is: %s" % max(l)
print "The average overlap is: %s" % numpy.mean(l)
#print "The standard deviation of overlap is: %s" % numpy.std(l)
			

