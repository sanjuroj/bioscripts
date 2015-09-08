#!/bin/env python2.7
import sys
import os
import re
import argparse
import subprocess
import re
import copy
import collections



def main():    
    
    args=processArgs()
    checkErrors(args)
    

    #nameConvertFile = "/raid1/home/bpp/jogdeos/cronn/geoSubs/nameConverts.tab"
    outDir = args.o or "./"
    
    sourceList = args.f
    if (args.f == None) :
        sourceList = (args.s,args.i)
    
    
    foundFiles={}
    noneFound=[]
    lineMismatches={}
    sourcefiles=[]

    #find the original source files (there may be more than one per line in the -f) and add them to an array
    for source in sourceList :
        sourcedir, filters, dest = source
        inputDir = sourcedir
        fileFilters = filters.split(",")
        filtercount = len(fileFilters)
        #get name conversions    
        #with open(nameConvertFile) as fd:
        #    nameConv = dict(line.strip().split(None, 1) for line in fd)
        fileList=[]

        for dirname,dirs,files in os.walk(inputDir):
            for f in files :
                passcount=0
                for filt in fileFilters :
                    #print "filt=%s, filename=%s" % (filt,f)
                    match=re.search(filt,f)
                    #print "matchval=",match
                    if match != None : passcount+=1
                
                #print "passcount=",passcount
                #print "file = ",f
                #print "ar",args.a
                if ((passcount==filtercount and args.a == False) or 
                    (passcount > 0 and args.a == True)) :
                    #print "yes!"
                    #print (dirname,f)
                    fileList.append(os.path.join(dirname,f))
            #print "filelist",fileList

        if (len(fileList) > 0) :
            if dest in foundFiles :
                foundFiles[dest]+=fileList
            else :
                foundFiles[dest]=fileList
        else :
            noneFound.append(source)
    
    
    processThis = collections.defaultdict(list)
    for outpath in foundFiles :
        fileTypeList = []
        foundFiles[outpath].sort
        peflag = 0
        

        for filename in foundFiles[outpath] :
            if (re.search("R2_\d+", filename) != None) :

                peflag=1
                break
        if peflag == 1 :
            #print foundFiles[outpath]
            #print "outpath="+outpath
            #print "name = "+foundFiles[outpath][0]
            outbase ="outpath"
            outsuffix = ""
            match = re.search(r"(.*)(\.f[ast]*q.*)",outpath)
            if (match != None) :
                outbase =  match.group(1)
                outsuffix = match.group(2)
                
            #print "outbase,suffix=%s %s" % (outbase,outsuffix)
            #sys.exit()
            for filename in foundFiles[outpath] :
                if (re.search("R2_\d",filename) == None) :
                    newoutpath = "%s_R1%s" % (outbase,outsuffix)

                    processThis[newoutpath].append(filename)
                else :
                    newoutpath = "%s_R2%s" % (outbase,outsuffix)
                    processThis[newoutpath].append(filename)
        else :
            #print outpath
            processThis[outpath]=copy.deepcopy(foundFiles[outpath])
        #print "outpath:"+outpath
        #print "\n".join(foundFiles[outpath])
       #print ""


    for key in processThis :
        #print "\n".join(processThis[key])
        processThis[key]=sorted(processThis[key])
        
    sFH = ""
    if args.l == False :
      sfilepath = outDir+"sourcefiles.txt"
      if os.path.isfile(sfilepath) == True :
        print "%s already exists. Can't overwrite.  Exiting." % (sfilepath)
        sys.exit()

      sFH = open (sfilepath,'w')

    outfiles=[]
    messages=[]
    
    for dest in sorted(processThis.keys()) :
        
        #check to see if zipped and unzipped files are being mixed
        #check to see if the source and destination files match in terms of their zipped status
        outfile = checkZip(processThis[dest],dest)
        
        #check if the outfile already exists and if so quit
        if (os.path.isfile(outfile)==True and args.l == False) :
            print "Please delete %s before proceeding" % (outfile)
            sys.exit()

        #now to the moving and counting
        sourceLines = 0 
        for sfile in processThis[dest] :
            #root,file=fileTup
            #infile=os.path.join(root,file)
            infile=sfile
            if args.l == False :
                sFH.write(infile+"\n")
            cmd="cat %s >> %s" % (infile,outfile)
            print "cmd="+cmd
            if (args.l == False) :
                subprocess.call(cmd, shell=True)
                tempLines = getLines(infile)
                try :
                    sourceLines+=tempLines
                except :
                    print "Couldn't count the number of lines in source"
        print ""

        if args.l != True :        
            print "Total lines in source: %s\n" % (sourceLines)
            destLines = getLines(outfile)
            if destLines == 'ERROR' :
                print "Couldn't count lines if the destination file"
            else :
                print "Total lines in destination: %s" % (destLines)
            outfiles.append(outfile)
            if (destLines != sourceLines) :
                addMismatch(lineMismatches,dest,source,sourceLines,destLines)
        
    if (args.l == False) :
      sFH.close()
    
    if (args.l != True) : 
    
        md5path = os.path.join(outDir,"md5sums")
        md5FH = open (md5path,'w')
        for file in outfiles :
            
            cmd = "md5sum %s" % (file)
            md5sum = subprocess.check_output(cmd,shell=True)
            md5FH.write(md5sum)
        md5FH.close()
        
        
        if (len(lineMismatches) > 0) :
            print "\nThere were line count mismatches for the follwing sources:"
            for key in lineMismatches :
                print lineMismatches[key]['source']
                print lineMismatches[key]['counts']
        else:
            print "\nAll files had matching line counts"
            
        print ""

    if (len(noneFound)==0) :
        print "At least one file was found for each directory input (which is good)"
    else :
        print "The following criteria sets had no matching files:"
        for dir in noneFound :
            print dir
            
    print ""
    
    for m in messages :
        print m+"\n"



def checkZip (filelist,dest) :

    outFilename = dest
    messages=[]
    zipcount = {'zipped':0, 'notzipped':0}
    for filename in filelist :
        #root,filename=fileTup
        sourcematch=re.search(".gz$",filename)
        if sourcematch==None :
            zipcount['notzipped']+=1
        else :
            zipcount['zipped']+=1

    #quit if the sources are mixed zipped and unzipped
    if (zipcount['notzipped'] != 0 and zipcount['zipped'] != 0) :
        print "The files that are supposed to go into %s are a mix of zipped and non-zipped files.  Check your inputs and try again." % (dest)
        print "\n".join(filelist)+"\n"
        sys.exit()

    #add a .gz to the end of the destination filename if the sources are all zipped
    if (re.search(".gz",outFilename)==None and zipcount['zipped'] > 0) :
        outFilename+=".gz"
        messages.append("A '.gz' was added to the end of %s, since the source appears to be zipped." % (outFilename))
    
    #remove the .gz if source is not zipped
    match = re.search("(.*).gz$",outFilename)
    if (match != None and zipcount['notzipped'] > 0) :
        outFilename = match.group(1)
        messages.append("The '.gz' was removed from the end of %s, since the source appears to be unzipped." % (outFilename))
    
    print "\n".join(messages)
    return outFilename
  
         
def addMismatch (container,key,source,scount,dcount):
    sourcetext="\t".join(source)
    container[key]={}
    container[key]['source']=sourcetext 
    container[key]['counts']="In=%s ,  Out=%s\n" % (scount,dcount)
    
    
    
def getLines(file):
    if (re.search(".gz",file)==None) :
        #cmd = "cat %s | grep -c \"\" " % (file)
        cmd = "cat %s | wc -l " % (file)
    else :
        #cmd = "zcat %s | grep -c \"\" " % (file)
        cmd = "zcat %s | wc -l " % (file)
    print "linecount cmd = "+cmd
    try :
        linecount = subprocess.check_output(cmd,shell=True)
        print linecount
        return int(linecount)
    except :
        return "ERROR"
    #return 0
    
def checkErrors(args):
    
    #if (args.i!=None and os.path.isfile(args.i) == False) :
    #    sys.exit("A file must be provided with the -i flag.")
    #if (args.s != None and os.path.isdir(args.s) == False):
    #    sys.exit("The argument you entered for -s is not a directory.")
    if (os.path.isdir(args.o)==False) :
        print "The value you provided with the -o paramaater is not a directory."
        sys.exit()

def processArgs():
    class MyParser(argparse.ArgumentParser):
        def error(self, message):
            sys.stderr.write('\nerror: %s\n\n' % message)
            self.print_help()
            sys.exit(2)
    
    class Checkerrors(argparse.Action) :
        def __call__(self,parser,namespace,value,option_string) :
            if (option_string=="-f") :
                
                if (os.path.isfile(value)==False) :
                    parser.error("The -f flag needs a valid filename")
                else :
                    filtlist = []
                    errors=[""]
                    filterLenError = 0
                    with open(value,'r') as fh :
                        for line in fh :
                            if (re.search('^[\s\n]+$',line)!=None) :
                                continue
                            if (re.search('^#',line)!=None) :
                                continue
                            line = line.rstrip("\n")
                            components = tuple(line.split("\t"))
                            if len(components) != 3 :
                                filterLenError = 1
                            if (os.path.isdir(components[0])==True) :
                                filtlist.append(components)
                            else :
                                errors.append("%s is an invalid dirname in %s" % (components[0],value))
                    
                    if filterLenError == 1 :
                        errors.append("You need 3 columns in your filter file")
                    
                    if len(errors) > 1 :
                        parser.error("\n".join(errors))
                    
                    setattr(namespace,self.dest,filtlist)
            
            if (option_string=="-s") :
                if (os.path.isdir(value)==False) :
                    parser.error("The value you proivded for the -s flag is not a valid directory")
                else :
                    setattr(namespace,self.dest,value)
    
    
    
    #argParser = MyParser(usage=("%s (sourceDir & filter) | filterFile" % (os.path.basename(sys.argv[0]))))
    argParser = MyParser(description="""Prepares a set of files for submission to NCBI (e.g. GEO or SRA databases).
                     First finds all files in the directory you have specified.  Checks the file name against a list
                     of filters that you provide (must pass all filters). 
                     """)

    group=argParser.add_mutually_exclusive_group(required=True)
    group.add_argument('-s', metavar="sourceDir", action=Checkerrors, help="The directory in which the sequence files can be found.")
    group.add_argument('-f', metavar="filterFile", action=Checkerrors, help="""A tab seperated file with source directory names in the first column, csv filter text (to filter in file names) in the second column,
                       and destination file in a third column.""")
    argParser.add_argument('-i', metavar="filter", help="Only use with the -s option.  Either a csv text value or a file with one csv text item per line.  Default=None.")
    argParser.add_argument('-a', action='store_true', help="Use an OR operator with the filter list.  Default is to use an AND operator (i.e. the file must pass all filters).")
    argParser.add_argument('-l', action='store_true', help="Just list the files that will be copied if the script is run without the -l flag.")
    argParser.add_argument('-o', metavar="outputdir", default="./", help="Output directory.  Default=./")
    
    #if len(sys.argv)==1:
    #    argParser.print_help()
    #    sys.exit(1)
    
    args = argParser.parse_args()
    return args



#This is required because by default this is a module.  Running this makes it execute main as if it is a script
if __name__ == '__main__':
    main()
