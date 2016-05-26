#!/usr/bin/python
import sys

''' Caesar cipher implementation in python '''

'''
#takes first arg
print 'Number of arguments:', len(sys.argv), 'arguments.'
print 'Argument List:', str(sys.argv[1])
'''

out = ''

for c in sys.argv[1]:
    c = chr(ord(c) + 3)
    out = out + c

print '', out
