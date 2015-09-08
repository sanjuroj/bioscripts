#!/bin/env python2.7
import sys
import os
import argparse
import re
import gzip

###########################
# Note this doesn't work for FASTA files
# Need to check if the header info gets processed when there is no space in the header
###########################

def main():
    args=processArgs()
    
    fileList = []
    if os.path.isfile(args.source) :
        fileList.append(os.path.abspath(args.source))
    elif os.path.isdir(args.source) :
        fileList = [os.path.abspath(fileName) for fileName in os.listdir(args.source)]
        
    else :
        print "The source you entered is neither a file nor a direcotry.  Exiting."
        sys.exit()
        
    if (args.source == args.out) :
            print "Can't use the same file/directory for input an output"
    
    for inPath in fileList :
        fileName = os.path.basename(inPath)
        outPath = os.path.join(args.out,fileName)
        if outPath == inPath :
            print "Outpath:%s can't equal input file: %s.  Exiting" % (outPath,inPath)
        fh = ""
        if re.search('.gz$',fileName) :
            print "Gzipped"
            fh = gzip.open(inPath,'r')
            
        else :
            print "Not gzipped"
            fh = open(inPath,'r')
            
            
        while True :
            header = fh.readline()
            data = fh.readline()
            if not data :
                break
            print header,
            print data,
            
        sys.exit()
        
    
    
def splitLine (string,chunkSize) :
    chunkSize = int(chunkSize)
    chunks = len(string)/chunkSize
    retArray = []
    print "chunkSize=%s, chunks=%s" % (chunkSize, chunks)
    for i in range(0,chunks*chunkSize,chunkSize) :
        retArray.append(string[i:i+chunkSize])
        
    
    return retArray
    


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
    argParser = MyParser(description="""Splits the reads in Fasta or Fastq files into smaller chunks
                         """)

    argParser.add_argument('source', metavar="file/dir", help="File or directory of fasta/q files")
    argParser.add_argument('out', metavar="file/dir", help="Output directory")
    argParser.add_argument('len', metavar="seqLength", help="Chunk size (e.g. 50 for 50bp chunks)")
    
    ap=argParser.parse_args()
    return ap




#This is required because by default this is a module.  Running this makes it execute main as if it is a script
if __name__ == '__main__':
    main()
    
