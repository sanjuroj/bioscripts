#!/usr/bin/env python2.7
import sys
import os
import argparse
import re
from collections import defaultdict 


#argParser = argparse.ArgumentParser()
#argParser.add_argument("xaa")
#argParser.parse_args()
#print args.xaa
  


def main():
    args=processArgs()
    checkErrors(args)

   
    errorReruns = set()
    chrysalisReruns = set()
    sgeExitReruns = set()
    hserrorReruns = set()
    filenameprefix = ""
    stdoutProcId = ""
    ofilePIDref = defaultdict(list)

    stdoutfile = os.listdir(args.stdoutDir)[0]
    match = re.search("([^\.]+)",stdoutfile)
    filenameprefix = match.group(1)
    match = re.search("(.*\.)",stdoutfile)
    stdoutProcId = match.group(1)
    for ofile in os.listdir(args.stdoutDir) :
        match = re.search("\.(\d+)",ofile)
        ofilePIDref[match.group(1)].append(ofile)
        #print ofilePIDs[match.group(1)];
        


    
    errorReruns = checkStderr(args.stderrDir,args.stdoutDir)
    chrysalisReruns = checkChrysalis(args.chrysalisDir)

    if args.s != None :
        sgeExitReruns = checkSGEexitcodes(args.s,args.stdoutDir,filenameprefix)
    if args.f != None :
        hserrorReruns = checkHserrors(args.f,args.stdoutDir,stdoutProcId,ofilePIDref)

    
    rerunIDs = errorReruns | chrysalisReruns | sgeExitReruns | hserrorReruns

    sys.stdout.write("Number of error files found = %s\n" % (len(errorReruns)))
    sys.stdout.write("Number of chrysalis comps with no fasta file = %s\n" % (len(chrysalisReruns)))
    sys.stdout.write("Number of butterfly runs that exited with an error status = %s\n" % (len(sgeExitReruns)))
    sys.stdout.write("Total number of comps to re-run = %s\n" % (len(rerunIDs)))
    

    
    commonErrAndSGEexit = ""
    commonReruns = ""
    uniqStdError = ""
    uniqNoFasta = ""
    uniqSGEexit = ""
    uniqHserror = ""
    if (args.f != None and args.s != None) :
        commonReruns = chrysalisReruns.intersection(sgeExitReruns,errorReruns,hserrorReruns)
        commonErrAndSGEexit = sgeExitReruns.intersection(errorReruns)
        uniqStdError = errorReruns - chrysalisReruns - sgeExitReruns - hserrorReruns
        uniqNoFasta =  chrysalisReruns - errorReruns  - sgeExitReruns - hserrorReruns
        uniqSGEexit =  sgeExitReruns - chrysalisReruns - errorReruns - hserrorReruns
        uniqHserror =  hserrorReruns - sgeExitReruns - chrysalisReruns - errorReruns
    elif (args.f != None and args.s == None) :
        commonReruns = chrysalisReruns.intersection(errorReruns,hserrorReruns)
        uniqStdError = errorReruns - chrysalisReruns - hserrorReruns
        uniqNoFasta =  chrysalisReruns - errorReruns - hserrorReruns
        uniqHserror =  hserrorReruns - chrysalisReruns - errorReruns
    elif (args.f == None and args.s != None) :
        commonReruns = chrysalisReruns.intersection(errorReruns,sgeExitReruns)
        commonErrAndSGEexit = sgeExitReruns.intersection(errorReruns)
        uniqStdError = errorReruns - chrysalisReruns - sgeExitReruns
        uniqNoFasta =  chrysalisReruns - errorReruns  - sgeExitReruns
        uniqSGEexit =  sgeExitReruns - chrysalisReruns - errorReruns
    else :
        commonReruns = chrysalisReruns.intersection(errorReruns)
        uniqStdError = errorReruns - chrysalisReruns
        uniqNoFasta =  chrysalisReruns - errorReruns


    print ""
    print "%s reruns were unique to checking for the presense of a fasta file." % (len(uniqNoFasta))
    print "%s reruns were unique to checking STDERR file sizes." % (len(uniqStdError))
    if (args.f != None) :
        print "%s reruns were unique to hserror files." % (len(uniqHserror))
    if (args.s != None) :
        print "%s reruns were unique to checking the SGE exit status." % (len(uniqSGEexit))
        print "%s reruns were common to SGE exit status and STDERR file sizes." % (len(commonErrAndSGEexit))
    print "%s reruns were common to all methods." % (len(commonReruns))




    if len(rerunIDs) > 0 and args.outputFile != None :
        fh = open(args.outputFile,'w')
        fh.write("\n".join(rerunIDs))
        fh.close()


def checkHserrors(hsdir,stdoutdir,ofPrefix,ofilePIDref) :
    rerunSet = set()
    #print "len=".len(os.listdir(hsdir))
    for hsFile in os.listdir(hsdir) :
        match = re.search("pid(\d+)\.",hsFile)
        jobId = match.group(1)
        if jobId in ofilePIDref :
            #stdOutFile = os.path.join(stdoutdir,ofPrefix+jobId)
            for stdoutfile in ofilePIDref[jobId] :
                with open(os.path.join(stdoutdir,stdoutfile),'r') as sofh :
                    rerunSet.add(sofh.readline().strip())
    

        else :
            print "Can't find hserr pid %s" % (jobId)
        
    return rerunSet
        
            
    

    
def checkSGEexitcodes (sgeExitCodeFile,stdoutdir,prefix) :

    rerunSet = set()
    with open(sgeExitCodeFile,'r') as sfh :
        for line in sfh :
            if re.search("code \d+.",line) != None and re.search("code 0.",line) == None :
                match = re.search("Job (.*) exited",line)
                jobid = match.group(1)
                stdoutfile = os.path.join(stdoutdir,(prefix+".o"+jobid))
                ofh = open(stdoutfile,'r')
                rerunSet.add(ofh.readline().strip())
                

    #print len(rerunSet)
    #sys.exit()
    return rerunSet


def checkChrysalis (chrysalisdir) :
     
    
    #counter = 0
    
    testedIDs = set()
    foundIDs = set()
    for wpath,wdirs,wfiles in os.walk(chrysalisdir) :
        
        for fn in wfiles :
            m = re.search("(c\d+).graph",fn)
            #print "fn="+fn
            if m == None :
                #print "no match"
                continue
            #print m.groups()
            compID = m.group(1)
            pmatch = re.search("(Cbin\d+)",wpath)
            comppath = pmatch.group(1)+"/"+compID
            testedIDs.add(comppath)
            m = re.search("allProbPaths",fn) 
            if m != None :
                foundIDs.add(comppath)

    missingIDs = testedIDs - foundIDs
    
    return missingIDs




def checkStderr (errdir,stdoutdir) :
    
    missingComps = set()
    if os.path.isdir(errdir) :
        haserrorFiles= []
        #fileList = os.listdir(args.dir)
        stderrFiles = os.listdir(errdir)
        for filename in stderrFiles:
            fullFile = "%s/%s" % (errdir,filename)

            if os.path.getsize(fullFile) != 0 :
                haserrorFiles.append(filename)
            
        sys.stdout.write("%s stderr files were found.\n" % (len(stderrFiles)))
        if len(haserrorFiles) == 0 :
            
            sys.stdout.write("No stderr files with size greater than 0 were found.\n")
            return missingComps
        

        stdoutfiles =  []
        #print "badfile"
        #print haserrorFiles[0]
        #print os.path.join(errdir,haserrorFiles[0])
        
        
        for filename in haserrorFiles :
            #print "filename = "+filename
            stdoutfile = os.path.join(stdoutdir,re.sub(".e",".o",filename))
            with open(stdoutfile,'r') as ofh :
                missingComps.add(ofh.readline().strip())
    
    
    return missingComps



def checkErrors(args):
    
    if os.path.isdir(args.chrysalisDir) == False:
        sys.exit("The chrysalisDir argument you entered is not a directory")


def processArgs():
    class MyParser(argparse.ArgumentParser):
        def error(self, message):
            sys.stderr.write('\nerror: %s\n\n' % message)
            self.print_help()
            sys.exit(2)

    argParser = MyParser()
    argParser.add_argument('chrysalisDir', help="Check for comps that don't have a .finished file. <Dir> should be the chrysalis directory from the Trinity run.")
    argParser.add_argument('stderrDir', help="Check for error file sizes that are non-zero.  <Dir> should be a directory that contains the STDERR output files.")
    argParser.add_argument('stdoutDir', help="A directory that contains the STDOUT output files.")
    argParser.add_argument('outputFile', help="Rerun id paths will be written to this file.  Must be provided if -e, -h, or -s flags are used.")
    argParser.add_argument('-s', metavar="<file>", help="Re-run comps that produced an sge error code.  <File> should contain sge exit codes.")
    argParser.add_argument('-f', metavar="<dir>", help="Re-run hs-error related comps.  <Dir> should be a directory that contains the hserror files .")
    
    
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