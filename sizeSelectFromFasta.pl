#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:hs:n:',\%opts); 

&varcheck;

my ($lenMin,$lenMax);
if ($opts{'s'}=~/-/){
	($lenMin,$lenMax) = (split("-",$opts{'s'}));
}
else{
	$lenMin = $opts{'s'};
	$lenMax = $opts{'s'};
}

open (FH,$opts{'f'}) or die "Can't open $opts{'f'}";
my ($header,$sequence)= ("","");
while (my $line=<FH>){
	chomp $line;
	
	next if $line=~/^#/;
	if($line=~/>/){
		
		if ($sequence ne "" && length($sequence) >= $lenMin && length($sequence) <= $lenMax){
			print "$header\n$sequence\n";
		}
			
		$header = $line;
		$sequence = "";
	}
	else{
		$sequence .= $line;
	}
}

sub varcheck {
	&usage if ($opts{'h'});
	my $errors = "";
	if (!$opts{'f'}){
		$errors .= "-f flag not provided\n";
	}
	elsif(!(-e $opts{'f'})) {
		$errors .= "Can't open $opts{'f'}\n";
	}
	if (!$opts{'s'}){
		$errors .= "-s flag not provided\n";
	}
	
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName <-f file> <-s size range> [-n read count]\n";
print <<PRINTTHIS;

Select sequences from a fasta that only correspond to certain sizes

-f Fasta formatted file to filter
-s Sizes to keep (e.g. 20-22 or 24);
-n minimum read count
	
PRINTTHIS
	exit;
}