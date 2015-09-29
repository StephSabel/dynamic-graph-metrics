#!/usr/bin/env python
# encoding: utf-8
# Written by Aapo Kyrola 
# http://stackoverflow.com/questions/28349805/extracting-plain-text-output-from-binary-file
import struct
from array import array as binarray 
import sys

inputfile = sys.argv[1]

data = open(inputfile).read()
a = binarray('c')
a.fromstring(data)

s = struct.Struct("f")

l = len(a)

print "%d bytes" %l

n = l / 4

for i in xrange(0, n):
    x = s.unpack_from(a, i * 4)[0]
    print ("%d %f" % (i, x))

