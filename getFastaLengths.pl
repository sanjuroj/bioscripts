#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:s',\%opts); 

&varcheck;

my $shortHeader = $opts{'s'} ? 1 : 0;
open (FA,$opts{'f'}) or die "Can't open $opts{'f'}\n";

my $line=<FA>;
chomp $line;
my $header;
if ($shortHeader == 1) {
	$line =~ /^>(\S+)/;
	$header = $1;
}
else {
	$header = $line;
}
my $seqLen = 0;

while ($line = <FA>){
	chomp $line;

	if( eof(FA) || $line=~/>/){
		#print "here\n";
		
		if ($line =~ />/){
			print "$header\t$seqLen\n";
			#print "here\n";
			if ($shortHeader == 1) {
				$line =~ /^>(\S+)/;
				$header = $1;
			}
			else {
				$header = $line;
			}
		#	print "new=$header";
		}
		else {
			$seqLen += length($line);
			print "$header\t$seqLen\n";
		}
		
		$seqLen = 0;
	}
	else {
		#print "bf=$seqLen, sc=$header\n";
		$seqLen += length($line);
		#print "af=$seqLen\n";
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
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName <-f file> [-s]\n";
print <<PRINTTHIS;

Measures the length of each element of a fasta file.

-s option returns only first field of the header
	
PRINTTHIS
	exit;
}

