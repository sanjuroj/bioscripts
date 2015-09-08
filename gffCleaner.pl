#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('hg:o:',\%opts); 

&varcheck;


open (GF,$opts{'g'}) or die "Can't open $opts{'g'}\n";
my $outFile = $opts{'o'} || "-";
open (OUT,">$outFile") or die "Can't open $outFile\n";
print OUT "##gff-version\t3\n";

while (my $line=<GF>){
   chomp $line;
   my ($id,$source,$type,$start,$end,$score,$strand,$phase,$note) = (split("\t",$line));
   if ($type =~ /mrna/i || $type =~ /cds/i || $type =~ /utr/i){
	  if ($type =~ /mrna/i && $note=~/parent/i){
		 $note=~s/parent=[^;]+[;]*?//i;
		 #print $note."\n";
	  }
	  
	  
	  
	  my @printArray = ($id,$source,$type,$start,$end,$score,$strand,$phase,$note);
	  print OUT join("\t",@printArray)."\n";
   
	  
   }
   
   
   
}


sub varcheck {
	&usage if ($opts{'h'});
	my $errors = "";
	if (!$opts{'g'}){
		$errors .= "-g flag not provided\n";
	}
	elsif(!(-e $opts{'g'})) {
		$errors .= "Can't open $opts{'g'}\n";
	}
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
   print "\nusage: perl $scriptName <-g file> [-o outfile]\n";

print <<PRINTTHIS;

Converts gff file to gff3 format, retaining only mRNA, CDS and UTR lines.
Functionality highly dependent on what the inital gff file looks like.

-g gff file to convert
-o optional file for output.  Defaults to STDOUT
	
PRINTTHIS
   exit;
}