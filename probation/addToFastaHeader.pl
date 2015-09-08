#!usr/bin/perl

use strict;
use warnings;

sub usage()
{
   print STDERR q
   ( Usage: addToFastaHeader.pl <matchfile> <fastaFile> <outfile>
   
   Adds info to a fasta file based on another file
   
   );
   exit;
}

if ( ( @ARGV == 0 ) || $ARGV[0] eq "-h" )   #no arguments or help option
{
      &usage();
}

my $infoFile = $ARGV[0];
my $fastaFile = $ARGV[1];
my $outFile = $ARGV[2];

open (IFILE,$infoFile) or die "Can't open $infoFile";
open (FFILE,$fastaFile) or die "Can't open $fastaFile";

my %infoLines;
while (<IFILE>) {
	chomp;
	my @tmpTokens = split(/\s/,$_);
	$tmpTokens[0] =~ s/>//;
	$infoLines{$tmpTokens[0]} = $tmpTokens[1];
}
close IFILE;

open (OFILE,">$outFile") or die "Can't open $outFile";

while (<FFILE>) {
	
	if (/[>]/){
		my @headerSplit = split(/[\t\s]/,$_,2);
		$headerSplit[0] =~ s/>//;
		if ($infoLines{$headerSplit[0]}){
			print OFILE ">".$infoLines{$headerSplit[0]}." $headerSplit[0] $headerSplit[1]";
		}
		else {
			print "failed to find $headerSplit[0]\n";
		}
	}
	else {
		print OFILE $_;
	}
	
	
	
}
