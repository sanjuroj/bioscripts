#!/bin/env python2.7
import sys
import os
import argparse
import re
from operator import itemgetter



def main():
    args=processArgs()

    seqs={}
    header=""
    geneid=""
    with open(args.fasta) as FH :
        for line in FH :
            match = re.match(">",line)
            if match != None :
                #print "header " + line
                match = re.search("(.+)_\d+\s",line)
                if match != None :
                    #print match.group(1)
                    geneid = match.group(1)
                    if not geneid in seqs :
                        seqs[geneid]=[]
                    header = line.strip()
                    #print "header="+header
                else :
                    print "We have a parsing problem.  \nLook at %s" % (line)
                    sys.exit()

            else : 
                
                seqs[geneid].append((header,line.strip()))
                #print "geneid,arraylen=%s, %s" % (geneid,len(seqs[geneid]))
                seqs[geneid].sort(key=lambda tup: len(tup[1]),reverse=True)
                #print seqs[geneid]
                #len1=len(seqs[geneid][0][1])
                #len2=len(seqs[geneid][1][1])
                #print seqs[geneid][1]
                if len(seqs[geneid])>args.n :
                    seqs[geneid].pop()
                #print seqs[geneid]
                #print "geneid,arraylen=%s, %s" % (geneid,len(seqs[geneid]))
                

    for key in seqs :
        print seqs[key][0][0]
        print seqs[key][0][1]
            
#def sortfastas (farray) :

    

def processArgs():
    class MyParser(argparse.ArgumentParser):
        def error(self, message):
            sys.stderr.write('\nerror: %s\n\n' % message)
            self.print_help()
            sys.exit(2)
    
    class Checkerrors(argparse.Action) :
        def __call__(self,parser,namespace,value,option_string) :
            if (option_string==None) :
                if (os.path.isfile(value)==False) :
                    parser.error("The -f flag needs a valid filename")
                else :
                    setattr(namespace,self.dest,value)
            
    
    
    
    #argParser = MyParser(usage=("%s (sourceDir & filter) | filterFile" % (os.path.basename(sys.argv[0]))))
    argParser = MyParser(description="""Get long ORFs from one or more sequences.  Assumes single line fasta sequences.
                         Assumes sequence headers are EMBOSS getorf format.
                         """)

    argParser.add_argument('fasta', metavar="fastafile", action=Checkerrors, help="Fasta file of source sequence(s)")
    argParser.add_argument('-n', metavar="integer", default=1,help="Number of longest sequences to keep. Default=1.")
    ap=argParser.parse_args()
    return ap




#This is required because by default this is a module.  Running this makes it execute main as if it is a script
if __name__ == '__main__':
    main()
    