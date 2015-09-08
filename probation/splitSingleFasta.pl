#!/usr/bin/perl

use strict;
use Getopt::Std;
use POSIX;

my %opts;
getopts('f:p:n:l:s',\%opts);
&varcheck;

open (FH,$opts{'f'}) or die "Can't open $opts{'f'}\n";

my $header = <FH>;
chomp $header;
my @lines = <FH>;
my $seq = join("",@lines);
$seq =~ s/\n//g;
#print $seq."\n";
my $seqLen = length($seq);

my $rawLen = int($seqLen / $opts{'n'});
#print "raw=$rawLen\n";
#print "raw=".$opts{'n'} * $rawLen."\n";
foreach (my $i = 0; $i < $opts{'n'}-1; $i++){
   print $header."_".($i+1)."\n";
   print substr($seq,$i*$rawLen,$rawLen)."\n";
}
print $header."_$opts{'n'}\n";
print substr($seq,($opts{'n'}-1)*$rawLen,$seqLen-(($opts{'n'}-1)*$rawLen))."\n";


=begin
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
print "fileswithmaxfa=$filesWithMaxFA\n";
print "minFaperfile = $minFAperFile\n";

open (FA,$opts{'f'}) or die "Can't open $opts{'f'}\n";

#my $lastHeader="";
while (my $line = <FA>){
   chomp $line;
   
   my $outName;
   if ($nametype eq "prefix"){
      $outName = $opts{'p'}."_$fileCounter";
   }
   else {
      $line=~/>(\S+)[\s]/;
      $outName = $1;
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
=cut
   
sub varcheck{
   my $errors = "";
   if (!$opts{'f'}) {
      $errors .= "No fasta file provided\n";
   }
   else{
      my $fastaCount = `grep \">\" -c $opts{'f'}`;
      if ($fastaCount != 1){
         $errors .= "There is more than one fasta header in your file\n";
      }
   }
   
   if (!$opts{'n'} && !$opts{'l'}){
      $errors .= "Error: No -n or -l parameter was provided\n";
   }
   
   if ($opts{'n'} && $opts{'l'}){
      $errors .= "Error: Pick either -n or -l as a parameter\n";
   }
   
   if ($errors ne ""){
      print STDERR $errors;
      &usage;
   }
}

sub usage()
{
   print STDERR "\nUsage: splitFasta <-f fastAfile> <-n fileCount> <-p prefix>\n";
   print STDERR "Splits a FASTA file into smaller individual files.  If you want the\n"; 
   print STDERR "output to be seqential \(e.g. scaff1, scaff2, etc\), include a name prefix\n";
   print STDERR "\(e.g. scaff for scaff1\).  Default is to use the first fasta header as the\n";
   print STDERR "file name.\n\n";
       
   print STDERR "-n flag will specifiy how many pieces you want.  -n 80 will split the\n";
   print STDERR "fasta into 80 roughly equivalent files.  -n with any number less than zero\n";
   print STDERR "will split the fasta into as many files as there are fasta headers.\n";
   print STDERR "Default is to split into individual files.\n";
	  
	   
   exit;
}
