#!/usr/bin/perl

use strict;
use warnings;

sub usage()
{
   print STDERR q
   ( Usage: addToFastaHeader.pl <fastaFile>
   
   Modifies fasta headers. Duh.  You will need to modify the script.
   
   );
   exit;
}

if ( ( @ARGV == 0 ) || $ARGV[0] eq "-h" )   #no arguments or help option
{
      &usage();
}

my $fastFile = $ARGV[0];
my $hashFile = $ARGV[1];
open (FFILE,$fastFile) or die "Can't open $fastFile\n";
open (HF,$hashFile) or die "Can't open $hashFile\n";
my %nameHash;
while (my $line = <HF>){
   chomp $line;
   my ($oName,$hName) = split("\t",$line);
   $nameHash{$oName}=$hName;
}
my $counter = 1;
while (my $fLine = <FFILE>) {
   if ($fLine =~ /^>(\S+)\s*/){
	  #change this section depending on what you want new headers to look like
	  my $remove = $1;
      if (!$nameHash{$remove}){
         print STDERR "$remove doesn't exist in the hash\n";
      }
	  else{
         my $insert = $nameHash{$remove};
         $fLine=~s/$remove/$insert/;
      }
	}
	
    else{
        print $fLine;
    }
}
