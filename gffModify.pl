#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:',\%opts); 

my $scriptName;
if ($0 =~ /\//){
	$0 =~ /\/.*\/(.+)$/;
	$scriptName = $1;
}
else {
	$scriptName = $0;
}

&varcheck;

open (FH,$opts{'f'}) or die "Can't open $opts{'f'}\n";
print "##gff-version\t3\n";
while (my $line=<FH> ){
	if ($line=~/^#/){
		print $line;
		next;
	}
	chomp $line;
	my @lineAr = split("\t",$line);
	my $note = pop @lineAr;
	$note =~ /fgenesh(\d+)/;
	my $gene = "fgenesh$lineAr[0]_$1";
	$lineAr[1] = "fgenesh_manual";
	if ($line =~ /mrna/i){
		$lineAr[2] = "fgenesh_mrna";
		print join("\t",@lineAr)."\tID=$gene;Name=$gene;Index=1\n";
	}
	if ($line =~/cds/i){
		$lineAr[2] = "fgenesh_exon";
		print join("\t",@lineAr)."\tParent=$gene\n";
	}
	
}





sub varcheck {
	my $errors = "";
	if (!$opts{'f'}){
		$errors .= "-f flag not provided\n";
	}
	elsif(!(-e $opts{'f'})) {
		$errors .= "Can't open $opts{'f'}\n";
	}
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	print "\nusage: perl $scriptName <-f file>\n";
print <<PRINTTHIS;

Generic script for modifying a GFF file.  Will need to be customized to whatever modifications
are required.
	
PRINTTHIS
	exit;
}
