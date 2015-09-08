#!/usr/bin/perl
use strict;
use warnings;

#my $queryPath = "/home/mcb/jogdeos/softwareAndscripts/scripts/qsubSample/queryFiles/";
my $queryPath = "../queryFiles/";
opendir (DIR,$queryPath) or die "Can't open $queryPath\n";
my $stop = 2;
while (my $file = readdir(DIR)) {
	next if ($file eq '.' || $file eq '..');
	#exit if $stop-- == 0;
	my $qFile = $queryPath.$file;
	my $outFile = $file."_qout";
	print $qFile."\n";
	#print qq(qsub -q 'rna1.q,rna2.q,rna3.q,rna4.q,rna5.q,rna8.q,rna10.q' blast.sh $qFile $outFile)."\n";
	`qsub -q 'rna9.q,rna10.q' ../blast.sh $qFile $outFile`;
}
	
