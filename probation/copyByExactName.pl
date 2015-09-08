#!/usr/bin/perl
# author: Shilpa
# Edited by rdb 04/10/05
#               05/10/05 to add single name specified on command line
# Edited by sj 06/13/07 to use hash table instead of array.  Much faster.
#              but must have the exact header

use strict;
use warnings;

sub usage()
{
   print STDERR q
   (   Usage: copyByExactName.pl <FASTA file> <outFile> [-f] <headerNameFile>
   or
   Usage: copyByExactName.pl <FASTA file> <outFile> [-f] <-n name1 name2 etc...>
    
    -f option will match only the first word of each FASTA header
    
  
   );
   exit;
}

if ( ( @ARGV < 2 ) || $ARGV[0] eq "-h" )   #no arguments or help option
{
      &usage();
}

my $seqFile=$ARGV[0];
my $outFile = $ARGV[1];
open ( inSeq, $seqFile ) or die "Unable to open ". $seqFile;
open (OFILE,">$outFile") or die "Unable to open ".$outFile;

my %searchNames;
my $segmentFlag=0;
my $searchFile;

if ($ARGV[2] eq "-f") {
   $segmentFlag = 1;
   if ($ARGV[3] eq "-n") {
	  &getSearchList(4);
   }
   else {
	  &loadSearchFile(3);
   }
}
else {
   if ($ARGV[2] eq "-n") {
	  &getSearchList(3);
   }
   else {
	  &loadSearchFile(2);
   }
}

my $printFlag=0;

while ( my $seqLine = <inSeq>) {
   if (substr($seqLine,0,1) eq ">"){
      my $name1;
	  if ($segmentFlag == 1){
		 $seqLine =~ /^(.+?)\s/;
		 $name1 = $1;
	  }
	  else {
		 $name1 = $seqLine;
	  }
	  
      my $name2 = $name1;
      $name2 =~ s/>//;
	  if (defined($searchNames{$name2})){
		 $printFlag=1;
		 print OFILE $seqLine;
         if ($searchNames{$name1}){
            $searchNames{$name1} = 0;
         }
         else {
            $searchNames{$name2} = 0;
         }
	  }
	  else{
		 $printFlag=0;
	  }
   }
   else {
	  if($printFlag == 1){
		 print OFILE $seqLine;
	  }
   }
}

close inSeq;

foreach my $k (keys %searchNames) {
   if ($searchNames{$k} == 1) {
      print "Could not find $k\n";
   }
}


sub getSearchList {
   my $i = shift;
   if ( $ARGV[$i]) {
	   while ($ARGV[$i]) {
		   $searchNames{$ARGV[$i]} = 1;
		   $i++;
	   }
   }

   else {
	  die "No names in search list. Terminating.";
   }
   
   
}

sub loadSearchFile {
   my $sIndex = shift;
   open ( inName, $ARGV[$sIndex] ) or die "Unable to open: ". $searchFile."\n";
   while (my $seqLine = <inName>){
	  $seqLine = &monge($seqLine);
      $searchNames{$seqLine} = 1;
   }
   close inName;
}

sub monge {
   my $text = shift;
   chomp $text;
   $/ = "\r";
   chomp $text;
   $/ = "\n";
   return $text;
}