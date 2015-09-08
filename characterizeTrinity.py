#!/bin/env python2.7
import sys
import os
import argparse
from collections import defaultdict
import re


def main():
    args=processArgs()
    
    assemblyValues = {}
    with open(args.seqfile,'r') as fh :
        priorcomp = ""
        priorsub = ""
        priorseq = ""
        for line in fh :
            line = line.strip('\r\n')
            if re.search('^>',line) != None :
                result = re.search('^>.*(c\d+).*(c\d+).*(seq\d+)',line)
                if result.lastindex != 3 :
                    print "The fasta header didn't match the pattern expected. Exiting."
                    sys.exit()
                comp,sub,seq = result.groups()
                #print "comp,sub,seq=%s, %s, %s" % (comp,sub,seq)
                if comp not in assemblyValues :
                    assemblyValues[comp] = {}
                    assemblyValues[comp][sub] = {}
                elif sub not in assemblyValues[comp] :
                    assemblyValues[comp][sub] = {}

                priorcomp = comp
                priorsub = sub
                priorseq = seq

            else :
                assemblyValues[priorcomp][priorsub][priorseq] = len(line)
                

        
    print assemblyValues

    compcount = len(assemblyValues)
    subcount = 0
    seqcount = 0
    seqspercomp = {}
    seqspersub = {}
    subspercomp = {}

    for comp in assemblyValues :
        thissubcount = len(assemblyValues[comp])
        if thissubcount in subspercomp :
            subspercomp[thissubcount] += 1
        else :
            subspercomp[thissubcount] = 1

        compseqcount = 0

        for sub in assemblyValues[comp] :
            thisseqcount = len(assemblyValues[comp][sub])
            if thisseqcount in seqspersub :
                seqspersub[thisseqcount] += 1
            else :
                seqspersub[thisseqcount] = 1

            subcount += 1
            compseqcount += thisseqcount

            for seq in assemblyValues[comp][sub] :
                seqcount += 1

        if compseqcount in seqspercomp :
            seqspercomp[compseqcount] += 1
        else :
            seqspercomp[compseqcount] = 1


    print "subspercomp=%s" % (subspercomp)
    print "seqspercomp=%s" % (seqspercomp)
    print "seqspersub=%s" % (seqspersub)




def processArgs():
    class MyParser(argparse.ArgumentParser):
        def error(self, message):
            sys.stderr.write('\nError: %s\n\n' % message)
            self.print_help()
            sys.exit(2)
    
    class Checkerrors(argparse.Action) :
        def __call__(self,parser,namespace,value,option_string) :
            if (option_string==None) :
                if (os.path.isfile(value)==False) :
                    parser.error("The 'dir' flag needs a valid filename.")
                else :
                    setattr(namespace,self.dest,value)
            
    
    
    
    #argParser = MyParser(usage=("%s (sourceDir & filter) | filterFile" % (os.path.basename(sys.argv[0]))))
    argParser = MyParser(description="""Characterizes Trinity output.  Looks at how many sequences exist in each comp and subcomp.""")

    argParser.add_argument('seqfile', metavar="", action=Checkerrors, help="A combined trinity sequence file.")
    ap=argParser.parse_args()
    return ap




#This is required because by default this is a module.  Running this makes it execute main as if it is a script
if __name__ == '__main__':
    main()
    