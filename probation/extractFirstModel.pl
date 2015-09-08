#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use vars qw($opt_f $opt_n $opt_i $opt_a);

my @searchNames;
getopts('f:n:i:a');
varcheck();

#load fasta file into memory and create array of models for each gene
my (%fastaDat,%fastaModels);
my $currentGene =  -1;
open (FA,$opt_f) or die "Can't open $opt_f\n";
while (my $line = <FA>){
   chomp $line;
   #print "$line\n";
   next if ($line =~ /^\n+$/);
   if ($line =~ />/) {
      $line =~ /^>(\S+)\s*/;
      $currentGene = uc($1);
      my ($geneID,$model) = split(/\./,$currentGene);
      #print "linewithcarrat = $line\n";
      #print "model = $model, gene=$gene\n";
      if (!$model){
         print STDERR "Fasta file may not contain multi model headers.  Exiting\n".
         exit;
      }
      push (@{$fastaModels{$geneID}},$model);
   }
   else {
      $fastaDat{$currentGene} .= $line;
   }
   #print "end loop\n";
}

#load search strings
if ($opt_n) {
   @searchNames = split( ' ',$opt_n);
   if ( @searchNames == 0 )
   {
      print STDERR "No names in search list. Terminating.\n";
      exit;
   }
}

elsif ($opt_i) {
   open (SEARCH,$opt_i) or die "Can't open $opt_i\n";
   @searchNames = <SEARCH>;
   chomp @searchNames;
   close SEARCH;
}
else {
   my %nameHash;
   foreach my $k (keys %fastaDat) {
      my @split = split(/\./,$k);
      $nameHash{$split[0]} = 1;
   }
   @searchNames = keys (%nameHash);
}

foreach(@searchNames){
   $_ = uc($_);
}

#print "searchidcount =.".@searchNames."\n";

#if the gene model exists, print the model with the lowest number
my $notFound = "";
foreach my $sName (@searchNames){
   
   if($fastaModels{$sName}){
      my @models = sort {$a<=>$b} @{$fastaModels{$sName}};
      my $fullName = $sName.'.'.$models[0];
      print ">$fullName\n";      
      print "$fastaDat{$fullName}\n";
   }
   else{
      $notFound .= "Couldn't find $sName\n";
   }
   
   
}

print STDERR "$notFound";


sub varcheck{
   
   if ($opt_i){
      if (!(-e $opt_i)){
         print STDERR "Check Failed: can't open $opt_i\n";
         usage();
      }
   }
   
   if (!(-e $opt_f)) {
      print STDERR "Check failed: can't open $opt_f\n";
      usage();
   }
   
   
}


sub usage()
{
   print STDERR q(
   Usage: extractFirstModel -f <FASTA file> [-i <file> | -n <list>] 
	
   Outputs the lowest numbered model with models sorted numerically.
   Search is case insensitive.
   Assumes gene name and model are separated by a period (.).  e.g. AT1G12345.1
    
   -i flag should be followed by a filename that contains a list of headers
   -n flag should be followed by a space separated list of headers
      (e.g. -n "geneID1 geneID2")
   If -i or -n are not used, the lowest numbered model of every gene will be output
      
   
	);
   exit;
}