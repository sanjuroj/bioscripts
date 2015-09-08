#!/usr/bin/perl

use strict;
use Getopt::Std;
use POSIX;

my %opts;
getopts('f:p:n:o:',\%opts);
&varcheck;

##################################
# Declare Variables
##################################


my $fileCounter=1;

my $fastaCount = `grep \">\" -c $opts{'f'}`;
#print "fastacount=$fastaCount\n";
#if ($fastaCount == 1 and $fastaCount < $opts{'n'})
if ($fastaCount < $opts{'n'}){
   print "The value entered for n is greater than the fasta count of $fastaCount\n";
   print "Exiting\n".
   exit;
}

my ($nametype,$minFAperFile,$filesWithMaxFA);

if (($fastaCount == $opts{'n'} || $opts{'n'} < 1) && !$opts{'p'}) {
   $nametype = "header";
}
else{
   $nametype = "prefix";
}

if ($opts{'n'} == $fastaCount || $opts{'n'} < 1){
   $minFAperFile = 1;
   $filesWithMaxFA = 0;
}
else {
   $minFAperFile = floor($fastaCount/$opts{'n'});
   $filesWithMaxFA = $fastaCount - ($minFAperFile * $opts{'n'});
}
print "files with max FA = $filesWithMaxFA\n";
print "min FA per file = $minFAperFile\n";

my $outDir = ".";
if ($opts{'o'}){
   $outDir = $opts{'o'};
   $outDir =~ s/\/$//;
}



##################################
# Start Main
##################################


open (FA,$opts{'f'}) or die "Can't open $opts{'f'}\n";

#my $lastHeader="";
while (my $line = <FA>){
   chomp $line;
   next if $line =~ /^#/;
   next if $line =~ /^[\n\r]+$/;
   my $outName = $outDir."/";

   if ($nametype eq "prefix"){
      $outName .= $opts{'p'}."_$fileCounter";
   }
   else {
      $line=~/>(\S+)\s*?/;
      $outName .= $1;
   }
   
   open (OUT,">$outName") or die "Can't open $outName for writing";
   print OUT $line."\n";
   
   my $currentFAperFile;
   if ($fileCounter<=$filesWithMaxFA){
      $currentFAperFile = $minFAperFile + 1;
   }
   else {
      $currentFAperFile = $minFAperFile;
   }
   
   for (my $i = 1; $i <= (($currentFAperFile*2)-1); $i++){
      $line = <FA>;
      chomp $line;
      if ($line=~/>/){
         print OUT "\n$line\n";
      }
      else {
         print OUT $line;
      }
      
   }
   print OUT "\n";
   $fileCounter++
}
   



close FA;


sub getFileName {
   
   
}
   
sub varcheck{
   my $errors = "";
   if (!$opts{'f'}) {
      $errors .= "No fasta file provided\n";
   }
   elsif(!(-e $opts{'f'})){
	  $errors .= "Fasta file doesn't exist\n"; 
   }
   
   if ($opts{'n'} && $opts{'n'} !~ /^\d+$/){
      $errors .= "-n parameter is not a number\n";
   }
   
   if ($opts{'o'} && !(-d $opts{'o'})){
	  $errors .= "-o parameter is not a directory"
   }
   
   if ($errors ne ""){
      print STDERR $errors;
      &usage;
   }
}

sub usage()
{
   
   my $scriptName = $0;
   $scriptName =~ s/\/?.*\///;
	
   print STDERR "\nusage: perl $scriptName <-f fastAfile> [-n, -p, -o]\n";
print <<PRINTTHIS;

Splits a FASTA file into smaller individual files.  If you want the
  output to be seqential (e.g. scaff1, scaff2, etc), include a name prefix
  (e.g. scaff for scaff1).  Default is to use the first fasta header as the
  file name.

Mandatory:
-f path to fasta file

Optional:
-n flag will specifiy how many pieces you want.  -n 80 will split the
   fasta into 80 roughly equivalent files.  Default is to split into individual files.
-p text prefix.  This will name headers and files sequentially.  For instance, using '-p chrom'
   will result in filenames chrom1, chrom2, etc...
-o directory name.  Output will be placed in this directory.  Default is current working directory.
	  
PRINTTHIS
   exit;
}