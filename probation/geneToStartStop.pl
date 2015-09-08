#!usr/bin/perl
use strict;

sub usage()
{
   print STDERR q
   ( Usage: geneToStartStop.pl <geneOfInterest> <geneFile> <output> <extend>
   
   Takes a file with scaffold and gene numbers, compares it to 
   a snapGene file, and outputs scaffold and start/stop positions for 
   each gene.  Adds the number passed in <extend> to both the start and stop
   positions.
   
   );
   exit;
}

if ( !@ARGV || $ARGV[0] eq "-h" )
{
	&usage();
}


my $gFile= $ARGV[0];
my $snapFile = $ARGV[1];
my $out = $ARGV[2];
my $addNum = $ARGV[3];
my @snap;
my @line;
my $scaffNum;
my $i=0;
my $oldScaff=0;
&loadSnaps();
open (GENES,$gFile);
open (OUTFILE,">$out");
while (<GENES>){
    my $gLine = $_;
    my @gTemp = split(/\t/,$gLine);
    my $gScaff = $gTemp[0];
    my $gNum = $gTemp[1];
    my $i = 0;
    while ($snap[$gScaff][$i]){
        my @snapLine = split(/\t/,$snap[$gScaff][$i++]);
        if ($snapLine[2] eq "gene"){
            my @snapGeneNum = split(/\./,$snapLine[8]);
            #my $test = $snapGeneNum[1]==$gNum ? "Yes" : "No";
            #print ($snapGeneNum[1]," equals ",$gNum,"?",$test);
            if ($snapGeneNum[1] == $gNum){
				my $start = $snapLine[3]-$addNum < 1 ? 1 : $snapLine[3] - $addNum;
				print (OUTFILE $gScaff,"\t",$start,"\t",($snapLine[4]+$addNum),"\n");
                last;
            }
        }
        
    }
}

close OUTFILE;


sub loadSnaps{
	open (EXFILE, "$snapFile");
	
	while (<EXFILE>) {
		
		@line = split(/\s+/,$_);
		#print "line0a=",$line[0],"\t";
		$line[0] =~ /(\d+)/;
		$scaffNum = $1;
		#print "line0b=",$scaffNum,"\t";
		if($oldScaff<$scaffNum){
			$i=0;
		}
		$snap[$scaffNum][$i++]=$_;
		$oldScaff=$scaffNum;
		#print "scaff=",$scaffNum,", i=",$i,"\n";
		
	}
	close EXFILE;
}
