#!/bin/env python2.7
import sys
import os
import argparse



def main():
    args=processArgs()
    
    
"""
def processArgs():
    class MyParser(argparse.ArgumentParser):
        def error(self, message):
            sys.stderr.write('\nerror: %s\n\n' % message)
            self.print_help()
            sys.exit(2)

    argParser = MyParser()
    argParser.add_argument('file', help="CHANGEME")
    
    if len(sys.argv)==1:
        argParser.print_help()
        sys.exit(1)
    
    args = argParser.parse_args()
    return args
"""

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
                    setattr(namespace,self.dest,value)
            
    
    
    
    #argParser = MyParser(usage=("%s (sourceDir & filter) | filterFile" % (os.path.basename(sys.argv[0]))))
    argParser = MyParser(description="""Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris rutrum
                         egestas magna, ac blandit odio pharetra non. Ut cursus ligula in arcu hendrerit
                         pretium id lobortis urna. Aenean a porttitor.
                         """)

    argParser.add_argument('file', metavar="", help="Changeme")





#This is required because by default this is a module.  Running this makes it execute main as if it is a script
if __name__ == '__main__':
    main()
    