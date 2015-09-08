#!/usr/bin/perl
# author: Sanjuro Jogdeo

use strict;
use warnings;

sub usage()
{
   print STDERR q
   ( Usage: grabTopBlastHit <Blast output FILE> [-s] 
      
    Grabs the first blast hit for each query.  This should be the best hit, given
	the way BLAST sorts the output.  Output format must be tabular.

	If -s option is used, self-blast hits will not be listed. 
	   
   );
   exit;
}

if ( ( @ARGV == 0 ) || $ARGV[0] eq "-h" )   #no arguments or help option
{
      &usage();
}

my $blastFile=$ARGV[0];
my $selfFlag = (exists $ARGV[1]) ? 1 : 0;
print $selfFlag."\n";
open (BFILE,$blastFile) or die "Can't open $blastFile";
my $prevQuery = "";
#print "#Filtered by grabTopBlastHit.pl to get first blast hit per query\n";
while (my $bLine = <BFILE>) {
   if ($bLine =~ /^\#/){

	  print $bLine;
   }
   else {
	  my @bArray = split(/\t/,$bLine);
	  
	  if ($selfFlag == 1) {
	  	if ($bArray[0] ne $prevQuery and $bArray[0] ne $bArray[1]){
		   print $bLine;
	 	 }
	  }
	  else {
		if ($bArray[0] ne $prevQuery) {
		   print $bLine;
	  	}
	  }	
   	  $prevQuery=$bArray[0];
   }
   
}
