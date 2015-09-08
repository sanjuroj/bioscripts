#!/usr/bin/perl
#need to add feature that warns of stop codons (i.e. * at end)
use strict;
use warnings;

sub usage()
{
   print STDERR<<END;

Usage: checkFastaSame.pl <FASTA file 1> <FASTA file 2> [-v] 

Checks to see if contents of FASTA files are same.  Must be modified
so header idents match.

-v verbose flag prints details of matches and mismatches

END

   exit;

}


if ( ( @ARGV == 0 ) || $ARGV[0] eq "-h" )   #no arguments or help option
{
   &usage();
}

my $fastFile1 = $ARGV[0];
my $fastFile2 = $ARGV[1];
my $vFlag = ($ARGV[2] && $ARGV[2] eq "-v") ? 1 : 0;
my $sameCount = 0;
my $diffCount = 0;
my @notin1Count;
my @notin2Count;

open (FAST1,$fastFile1) or die "Can't open first fasta file";
open (FAST2,$fastFile2) or die "Can't open second fasta file";

my %fast1Hash;
my $aminoSeq="";
my $firstFlag = 1;
my $geneID;

#load first FASTA file into memory
while (my $fastLine=<FAST1>){
   next if $fastLine =~ /^\s*#/;
   next if $fastLine =~ /^\s*$/;
   chomp $fastLine;
   
   if (substr($fastLine,0,1) eq ">"){

      if ($firstFlag != 1){
         $fast1Hash{$geneID} = $aminoSeq;      
      }

      $firstFlag = 0;
      $fastLine =~ /^>(\S+)[\s]*/;
	  $geneID = $1;
	  $aminoSeq = "";
   }
   else {
      $fastLine =~ s/[\n\*]//g;
	  $aminoSeq .= $fastLine;
   }
}
$fast1Hash{$geneID} = $aminoSeq;
close FAST1;

my $searchID;
$aminoSeq = "";
$firstFlag = 1;

while (my $fastLine = <FAST2>){
   next if $fastLine =~ /^\s*#/;
   next if $fastLine =~ /^\s*$/;
   chomp $fastLine;

   if (substr($fastLine,0,1) eq ">"){
       if ($firstFlag == 1){
         $fastLine =~ /^>(\S+)[\s]*/;
         $searchID = $1;
         $aminoSeq = "";
         $firstFlag = 0;
         next;
      }

      if ($fast1Hash{$searchID}){

         if ($fast1Hash{$searchID} eq $aminoSeq){
            print "$searchID match\n" if $vFlag == 1;
            $sameCount++
         }
         else{
            print "$searchID different\n" if $vFlag == 1;
            print "file1=".$fast1Hash{$searchID}."\n" if $vFlag == 1;
            print "file2=".$aminoSeq."\n" if $vFlag == 1;
            $diffCount++;
         }
         $fast1Hash{$searchID} = 1;
      }

      else {
         print "$searchID found in file2, not in file1\n" if $vFlag == 1;
         push (@notin1Count,$searchID);
      }
      
      $fastLine =~ /^>(\S+)[\s]*/;
	  $searchID = $1;
	  $aminoSeq = "";

   }
   else {
      $fastLine =~ s/[\n\*]//g;
	  $aminoSeq .= $fastLine;
   }

}

if ($fast1Hash{$searchID}){
   if ($fast1Hash{$searchID} eq $aminoSeq){
      print "$searchID match\n" if $vFlag == 1;
      $sameCount++;
   }
   else{
      print "$searchID different\n" if $vFlag == 1;
      print "file1=".$fast1Hash{$searchID}."\n" if $vFlag == 1;
      print "file2=".$aminoSeq."\n" if $vFlag == 1;
      $diffCount++;
   }
   $fast1Hash{$searchID} = 1;
}
else {
   print "$searchID found in file2, not in file1\n" if $vFlag == 1;
   push(@notin1Count,$searchID);
   
}

foreach my $k (keys %fast1Hash){
   if ($fast1Hash{$k} ne 1){
	  print "$k found in file1, not in file2\n" if $vFlag == 1;
      push (@notin2Count,$k);
   }
}

print "same sequence count:  $sameCount\n";
print "different sequence count:  $diffCount\n";
print "found in file1 but not in file2 count:  ".@notin2Count."\n";
print "found in file2 but not in file1 count:  ".@notin1Count."\n";
if ($vFlag == 1 && @notin2Count < 20 && @notin2Count > 0){
   print "\nFound in file1 but not in file2:\n".join("\n",@notin2Count)."\n";
}
if ($vFlag == 1 && @notin1Count < 20 && @notin1Count > 0){
   print "\nFound in file2 but not in file1:\n".join("\n",@notin1Count)."\n";
}


