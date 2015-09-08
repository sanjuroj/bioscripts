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
    
    if args.r != False :
        rCount = countResidues(args.i,args.type)
        print "Residues: ",rCount
        sys.exit()
    
    fastaDict=loadFasta(args.i)
    fastaDict=getFastaStats(fastaDict)
    
    fastaOrder = fastaDict.keys()
    if (args.s!=None):
        fastaOrder=orderFasta(fastaDict,args.s,args.d)
    print "\n".join(fastaOrder)
    #for fa in fastaOrder:
        #print ">%s: %s\n%s" % (fa,fastaDict[fa]['length'],fastaDict[fa]['seq'])
        #print ">%s\n%s" % (fa,fastaDict[fa]['seq'])
        
        
    args.i.close()
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
            
def countResidues (filename,ftype): 
    
    resCount = 0
    for header,seq,qual in fiterator(filename,ftype) :
        resCount += len(seq)
        
    return resCount

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


#def fiterator (fileloc,ftype) :
def fiterator (fh,ftype) :
    

    
    if ftype == 'fasta' :
        seq = ''
        header = ''
        qual = ''
    
        for line in fh:
            line = line.strip()
            if line[0] == '>' :
                if seq != '' :
                    yield header,seq,qual
                    seq = ''
                header = line
            else:
                seq += line
        
        if seq != '':
            yield header,seq,qual
            
            
    if ftype == 'fastq' :
        header = ''
        seq = ''
        pip = ''
        qual = ''
        for line in fh:
            #print "line",line
            line = line.strip()            
            if header == '' :
                header = line
                #print "just assigned",header
                if header[0] != '@' :
                    print "Invalid fastq format.  This should be a header but it's not: %s\nExiting" % (line)
                    sys.exit()
            elif seq == '' :
                seq = line
            elif pip == '' :
                pip = line
            elif qual == '' :
                qual = line
                if len(header) == 0 or \
                    len(seq) == 0 or \
                    len(pip) == 0 or \
                    len(qual) == 0 :
                    
                    print "This is a disaster. Exiting"
                    sys.exit()
                else :
                    yield header,seq,qual
                    #print "header",header
                    header = ''
                    seq = ''
                    pip = ''
                    qual = ''
                    
    

        
    '''
    header = ''
    quality = ''
    with open(fileloc,'r') as fh :
        while True :
            try :
                if header == '' :
                    header = fh.readline().strip()
                
                
                if ftype == 'fasta' :
                    sequence = ''
                    for line in fh.readline() :
                        line.strip()
                        if re.search('^>',line) == None :
                            sequence += line
                        else :
                            break
                
                elif ftype == 'fastq' :
                    sequence = fh.readline().strip()
                    pip = fh.readline()
                    quality = fh.readline().strip()
                
                else :
                    print "You must choose either fasta or fastq"
                    sys.exit()
                print "head=",header
                yield header,sequence,quality
            except Exception as e :
                return header,sequence,quality
    '''


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
    argParser.add_argument('-i', help="A properly formatted fasta file", type=argparse.FileType('r'), default=sys.stdin)
    argParser.add_argument('type', help="fasta or fastq", choices=['fasta','fastq'])
    argParser.add_argument('-s', metavar='sort', help='Enter either "name" or "length"', choices=['name','length'], default=None)
    argParser.add_argument('-d', metavar='direction', help='Enter either "asc" or "desc".  Defaults to "asc"', choices=['asc','desc'], default=None)
    argParser.add_argument('-r', action = 'store_true', help='Counts the number of residues in the file')
    
    
    args = argParser.parse_args()
    return args



#This is required because by default this is a module.  Running this makes it execute main as if it is a script
if __name__ == '__main__':
    main()
    
'''A few things to remember:
-tuples are immutable.  Once you create one, its contents can't be changed, unlike a list.


'''