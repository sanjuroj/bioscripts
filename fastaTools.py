#!/usr/bin/env python2.7
import sys
import os
import argparse
import re
from operator import itemgetter

#God this is dumb.  This needs to be done so python doesn't throw an error when you pipe it to head
import signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)

#argParser = argparse.ArgumentParser()
#argParser.add_argument("xaa")
#argParser.parse_args()
#print args.xaa
  


def main():
    args=processArgs()
    checkErrors(args)
    
    fastaDict=loadFasta(args.file)
    fastaDict=getFastaStats(fastaDict)
    
    fastaOrder = fastaDict.keys()
    if (args.s!=None):
        fastaOrder=orderFasta(fastaDict,args.s,args.d)
    print "\n".join(fastaOrder)
    #for fa in fastaOrder:
        #print ">%s: %s\n%s" % (fa,fastaDict[fa]['length'],fastaDict[fa]['seq'])
        #print ">%s\n%s" % (fa,fastaDict[fa]['seq'])
        
    #this is done to prevent a python error on some head functions
    
    try:
        sys.stdout.close()
    except:
        pass
    try:
        sys.stderr.close()
    except:
        pass
    
def getFastaStats(faDict):
    for fa in faDict:
        faDict[fa]['length']=int(len(faDict[fa]['seq']))
        
    return faDict

def loadFasta(file):
    rdict={}
    currid=""
    with open (file, "r") as f:
        #if (re.match("\s*#")):
        #    continue
        #if (fl=="\n"):
        #    continue
        
        for line in f:
            if (re.match("\s*#",line)):
                continue
            if (line=="\n"):
                continue
            line = line.rstrip('\n')
            if (re.match(">",line)):
                currid=line.lstrip(">")
            else:
                try:
                    rdict[currid]['seq']+=line
                except:
                    rdict[currid]={}
                    rdict[currid]['seq']=line
        
    return rdict   
            
    
def orderFasta(faDict,stype,sdirection):
    keylist = faDict.keys()
    srev = False if sdirection=='asc' else True
    
    if(stype=='id'):
        keylist=sorted(keylist, reverse=srev)
    else:
        try:
            faDict[keylist[0]]['length']
        except:
            faDict = getFastaStats(faDict)
        
        
        keylist=sorted(keylist,key = lambda x: (faDict[x]['length']), reverse=srev)
        
    
    
    return keylist


def checkErrors(args):
    
    if (os.path.isfile(args.file) == False):
        sys.exit("The argument you entered is not a file")


def processArgs():
    class MyParser(argparse.ArgumentParser):
        def error(self, message):
            sys.stderr.write('\nerror: %s\n\n' % message)
            self.print_help()
            sys.exit(2)

    argParser = MyParser()
    argParser.add_argument('file', help="A properly formatted fasta file")
    argParser.add_argument('-s', help='Enter either "name" or "length"', choices=['name','length'], default=None)
    argParser.add_argument('-d', help='Enter either "asc" or "desc".  Defaults to "asc"', choices=['asc','desc'], default=None)
    
    if len(sys.argv)==1:
        argParser.print_help()
        sys.exit(1)
    
    args = argParser.parse_args()
    return args



#This is required because by default this is a module.  Running this makes it execute main as if it is a script
if __name__ == '__main__':
    main()
    
'''A few things to remember:
-tuples are immutable.  Once you create one, its contents can't be changed, unlike a list.


'''