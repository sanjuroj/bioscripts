#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:o:cteha',\%opts); 

my $scriptName;
if ($0 =~ /\//){
	$0 =~ /\/.*\/(.+)$/;
	$scriptName = $1;
}
else {
	$scriptName = $0;
}

my $out = "-"; #this will direct output to stdout
&varcheck;

open (OUT,">$out") or die "Can't open $out\n";
open (IN, $opts{'f'}) or die "Can't open $opts{'f'}\n";
my $sequence = "";
my $firstLoop = 1;
while (my $line = <IN>){
	
	next if $line =~ /^#/;
	next if $line =~ /^\n+$/;
	
	if ($line =~ />/){
		chomp $line;
		if ($firstLoop == 0){
			&printSeq($sequence,\*OUT);
		}
		$firstLoop = 0;
		if ($opts{'e'} || $opts{'a'}){
			$line =~ /^(>[^\s]+)/;
			print OUT $1."\n";
		}
		else{
			print OUT $line."\n";
		}
		$sequence = "";
	}
	elsif (eof(IN)){
		$sequence .= $line;
		&printSeq($sequence,\*OUT);
	}
	else {
		$sequence .= $line;
	}
}


sub printSeq {
	my $seq = shift;
	my $fh = shift;
	chomp $seq;
	if ($opts{'c'} || $opts{'a'}){
		$seq =~s/[\n\r]//g;
	}
	if ($opts{'t'} || $opts{'a'}){
		if (substr($seq,-1) eq "X" || substr($seq,-1) eq "*"){
			$seq = substr($seq,0,-1);
		}
	}
	print $fh $seq."\n";
}



sub varcheck {
	if ($opts{'h'}){
		&usage();
	}
	
	my $errors = "";
	if (!$opts{'f'}){
		$errors .= "-f flag not provided\n";
	}
	elsif(!(-e $opts{'f'})) {
		$errors .= "Can't open $opts{'f'}\n";
	}
	
	if ($opts{'o'}){
		$out = $opts{'o'};
	}
	
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	print "\nusage: perl $scriptName <-f file> [-c -s -t -o <file>]\n";
print <<PRINTTHIS;

Cleans a fasta file with the following options
-c Converts a multiline Fasta sequence to a single line
-e Eliminates extra header text (anything after the >header)
-t Trims 'X' and '*' from the end of sequences

-a All cleaning functions should be done

-o <file> directs output to the file specified
	
PRINTTHIS
	exit;
}