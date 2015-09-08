#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('g:l:o:vc',\%opts); 

&varcheck;

my @list = `cat $opts{'l'}`;
my $outFile = $opts{'o'} || "-";
open (FH,$opts{'g'}) or die "Can't open $opts{'g'}\n";
open (OUT,">$outFile") or die "Can't open $outFile\n";
print OUT "##gff-version\t3\n" if $opts{'c'};

if ($opts{'v'}){
	while (my $line=<FH>){
		next if $line =~/#/;
		my $foundFlag="false";
		foreach my $gene (@list){
			chomp $gene;
			if ($line=~/$gene[,;\n]/){
				$foundFlag="true";
				last;
			}
		}
		print OUT $line if $foundFlag eq "false";
		
	}
}
else{
	while (my $line=<FH>){
		next if $line =~ /#/;
		foreach my $gene (@list){
			chomp $gene;
			if ($line=~/$gene[,;\n]/){
				print OUT $line;
				last;
			}
		}
	}
}


sub varcheck {
	my $errors = "";
	if (!$opts{'g'}){
		$errors .= "-g flag not provided\n";
	}
	elsif(!(-e $opts{'g'})) {
		$errors .= "Can't open $opts{'g'}\n";
	}
	if (!$opts{'l'}){
		$errors .= "-l flag not provided\n";
	}
	elsif(!(-e $opts{'l'})) {
		$errors .= "Can't open $opts{'l'}\n";
	}
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName <-g gff file> <-l gene list> [-o -v -c]\n";
print <<PRINTTHIS;

Extracts genes from gff file.  Script is necessary because grep is too greedy and
grep -f can't be used to funnel a list into a regex.

Assumes that the gene name is in the note and is followed by one of ";,\\n".
Skips any blank lines or lines beginning in "#".

-o file.  Specifies the optional output file.  Default output is to STDOUT.
-c (flag).  Will print "##gff-version  3" at the head of the file.
-v (flag).  Will print all genes EXCEPT for the ones listed in the -l file.
	
PRINTTHIS
	exit;
}