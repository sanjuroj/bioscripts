#!/bin/env python2.7
import sys
import os
import argparse




def main():
    args=processArgs()    
    #print args.fasta
    readFasta(args.file)
    
    
    
    

def processArgs():
    argParser = argparse.ArgumentParser()
    argParser.add_argument('file', help="fasta file")
    argParser.add_argument('-p',
                           help="paired end file - will output paired sequences from both files")
    argParser.add_argument('reads', help="number of reads you want to output", type=int)
    
    if len(sys.argv)==1:
        argParser.print_help()
        sys.exit(1)
    
    args = argParser.parse_args()
    return args

def readFasta(filename):
    filehandle = open(filename,'r')
    lines = filehandle.readlines()
    for line in lines:
        if line.
        print line,
    
    
    
    filehandle.close()




def readFastq(filename):
    filehadle = open(filename,'r')

#This is required because by default this is a module.  Running this makes it execute main as if it is a script
if __name__ == '__main__':
    main()


"""
from Bio import SeqIO                                                               
import sys                                                                          
                                                                                    
wanted = [line.strip() for line in open(sys.argv[2])]                               
seqiter = SeqIO.parse(open(sys.argv[1]), 'fasta')                                    
SeqIO.write((seq for seq in seqiter if seq.id in wanted), sys.stdout, "fasta")
"""



"""
import random

def shuffle(ary):
    a=len(ary)
    b=a-1
    for d in range(b,0,-1):
      e=random.randint(0,d)
      if e == d:
            continue
      ary[d],ary[e]=ary[e],ary[d]
    return ary
"""

