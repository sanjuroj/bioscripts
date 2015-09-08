#!/usr/bin/perl
use strict;
use Getopt::Std;
use vars qw($opt_s $opt_r $opt_n $opt_o $opt_p $opt_f);

getopts('srno:p:f:');

sub usage()
{
   print STDERR q
   ( Usage: seqExtract.pl -p <startStops> -f <fastA> -o <output> [-r] [-s] [-n]
   
   Takes a file with tab delimited scaff number, start, and stop positions and
   extracts the sequence data from a fastA file (i.e. can be used for any fastA
   file, aa and dna).  The scaffold identifiers in the input file should
   correspond to the scaffold ids in the scaffold fasta file.  First three
   arguments are mandatory.

   -r is optional.  If included, the script will reverse complement all
   sequences.
   
   -s optional.  Selectively reverse complements sequences based on their order
   in the Start/Stop file (i.e. if the start position is greater than the stop
   position, the sequence will get reverse complemented).
   
   -n is optional.  If included, the script will use a 4th column from the
   input file to name each fasta header (you should be sure they are unique).
   By default, the unique id will be an internally generated
   counter, followed by the start stop postions and the original header.
   
   );
   exit;
}

if (!$opt_f or !$opt_p or !$opt_o) {
   &usage();
}

my $posFile=$opt_p;
my $fastFile=$opt_f;
my $outFile=$opt_o;
my ($reverseFlag,$nameFlag);


open (PFILE,$posFile) or die "Can't open position file $posFile";
open (FASTA,$fastFile) or die "Can't open Scaffold file $fastFile";
open (OFILE,">$outFile") or die "Can't open output file $outFile";

#read in the FASTA file
my %fastaData;
my $scaffID="";

while (my $fastLine=<FASTA>) {
   if (substr($fastLine,0,1 ) eq '>'){
      $fastLine =~ />(\S+)\s/;
      $scaffID = $1;
      print "reading ".$scaffID."\n";
  }
  else {
      chomp $fastLine;
     $fastLine =~ s/[\n\r]//g;
     $fastaData{$scaffID} .= $fastLine;
  }
}


close FASTA;
my @positions;
{
   local $/="";
   my $positions = <PFILE>;
   $positions =~ s/\r\n//g;
   $positions =~ s/\r/\n/g;
   @positions = split(/\n/,$positions);
}
close PFILE;

my $counter=0;
my $totalLen = 0;
foreach my $posLine (@positions) {
	$posLine =~ s/\n//;
	$posLine =~ s/\r//;
    my ($qScaff,$qStart,$qStop,$qName);
    if ($opt_n == 1){
      ($qScaff,$qStart,$qStop,$qName) = split(/\t+/,$posLine);
    }
    else {
      ($qScaff,$qStart,$qStop) = split(/\t+/,$posLine);
    }
    
    my ($extractStart,$qLen);
    my $reverseFlag = 0;
    if ($qStop > $qStart) {  
      $extractStart = $qStart;
      $qLen = $qStop - $qStart + 1;
      if ($opt_r){
         $reverseFlag = 1;
      }
    }
    else {
      $extractStart = $qStop;
      $qLen = $qStart - $qStop + 1;
      if ($opt_r or $opt_s){
         $reverseFlag = 1;
      }
    }
    
	if ($opt_n){
	  print (OFILE ">$qName $qScaff\_$qStart\_$qStop\n");
	}
	else{
	  print (OFILE ">seqID=".$counter++." $qScaff\_$qStart\_$qStop\n");
	}
    
    if (length($fastaData{$qScaff}) >= $qStop){
      my $outString = substr($fastaData{$qScaff},$extractStart-1,$qLen);
      if ($reverseFlag == 1){
          $outString = reverse($outString);
          $outString =~ tr/ATCG/TAGC/;
      }
      print OFILE "$outString\n";
    }
    else {
      print "$posLine stop position exceeded scaffold length\n";
    }
    $totalLen += $qLen;

}
print "total sequence length=$totalLen\n";
close OFILE;


