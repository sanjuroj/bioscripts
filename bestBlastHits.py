#!/usr/bin/env python2.7
# the lines should be grouped by queries (as usual, do sort file.blast if not)
import os
import string
import sys
import re
import argparse


def main():
    args=processArgs()

    
    #############--Settings--######################
    blastres = sys.argv[1]
    queryCol = 0
    evalCol = int(args.e) - 1
    bitScoreCol = int(args.b) -1
    tolerance = .00001
    #need min Cols to get rid of stub lines that sometimes appear
    minColumns = 12
    
    #############--Main--######################
    
    try:
        Hits=open(blastres, 'r')
    except IOError, e:
        print "file not found or unreadable: ",blastres
        pass
        
    #bestHit = Hits.readline().split("\t")
    bestHit = ""
    maxscore = 0
    mineval = 1000000
    query = ""
    
    discards = []
    
    for hit in Hits:
        #print "hit",hit
        checkBlank = re.search('^[\s\n]+$',hit)
        if checkBlank != None :
            print "Blank Line"
            sys.exit()
        
        hitSplit=hit.split("\t")
        if len(hitSplit) < minColumns :
            discards.append(hit)
            continue
        
        testEval = float(hitSplit[evalCol])
        testScore = float(hitSplit[bitScoreCol])
        
        if query != hitSplit[queryCol]:
            if bestHit != "" :
                print bestHit,
            query = hitSplit[queryCol]
            maxscore = testScore
            mineval = testEval
            bestHit = hit
        elif maxscore < testScore :
            bestHit = hit
            maxscore = testScore
            mineval = testEval
        elif abs(maxscore - testScore) < tolerance and mineval > testEval :
            bestHit = hit
            mineval = testEval
            
    
    Hits.close()
    print bestHit,
    
    if len(discards) > 0 :
        sys.stderr.write("These lines were discarded:\n")
        sys.stderr.write("\n".join(discards))
                        
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
                    parser.error("The -f flag needs a valid filename")
                else :
                    setattr(namespace,self.dest,value)
            
    
    
    
    #argParser = MyParser(usage=("%s (sourceDir & filter) | filterFile" % (os.path.basename(sys.argv[0]))))
    argParser = MyParser(description="""Extracts the best blast hit out of a blast results file.  File should already be sorted by query.
                         """)

    argParser.add_argument('file', metavar="file", action=Checkerrors, help="Blast output file")
    group = argParser.add_argument_group('Sort Parameters','At least one of these is required, if both are used, bitscore will be evaluated before e-value.')
    group.add_argument('-e', metavar="", help="Column number of evalue")
    group.add_argument('-b', metavar="", help="Column number of bitscore")
    ap=argParser.parse_args()
    return ap




#This is required because by default this is a module.  Running this makes it execute main as if it is a script
if __name__ == '__main__':
    main()
    