#!/usr/bin/perl
# author: Sanjuro Jogdeo

use strict;
use warnings;

sub usage()
{
   print STDERR q
   ( Usage: selectRandomLines.pl <FILE> <selLines>
      
    Selects <selLines> number of lines from <FILE> randomly.
	   
   );
   exit;
}

if ( ( @ARGV == 0 ) || $ARGV[0] eq "-h" )   #no arguments or help option
{
      &usage();
}

my $inFile=$ARGV[0];
my $lineCount = $ARGV[1];
if (!$lineCount =~ /\d+/){
   die "Please enter a positive integer for the number of lines you want";
}

open (INFILE,$inFile) or die "Can't open $inFile";
my @lineArray;
{
   local $/="";
   my $lineScalar = <INFILE>;
   $lineScalar =~ s/\r\n/\n/g;
   $lineScalar =~ s/\r/\n/g;
   @lineArray = split(/\n/,$lineScalar);
}

close INFILE;
if (@lineArray < $lineCount) {
   die "You've asked for more lines than are in the file";
}

while ($lineCount > 0) {
   my $lineIndex = rand()*(@lineArray-1);
   $lineIndex =~ /^(\d+)./;
   $lineIndex = $1;
   $lineCount--;
   #my $printLine = $lineArray[$lineIndex];
   #$printLine =~ /;trID=(.+)[;\n]/;
   #print "$1\n";
   print "$lineArray[$lineIndex]\n";
   splice (@lineArray,$lineIndex,1);
   
}