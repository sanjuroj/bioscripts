#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
#use vars qw($opt_f);

my %opts;
getopts('f:',\%opts); 

&varcheck;

my ($outPre,$outPost,$outName);
if ($opts{'f'} =~ /\./){ 
	$opts{'f'} =~ /(.*)\.(.*)/;
	$outName = $1."_trim\.".$2;
}
else {
	$outName = $opts{'f'}."_trim";
}


open (FA,$opts{'f'}) or die "Can't open $opts{'f'}\n";
open (OF,">$outName") or die "Can't open out\n";
my %headerInfo;
my $sequence="";
while (my $line = <FA>){
	chomp $line;
	if ($line =~ />/ || eof FA) {
		if ($sequence ne "" || eof FA){
			$sequence .= $line if eof FA;
			my $trimmedLen = $headerInfo{'stop'} - $headerInfo{'start'} + 1;
			my $trimmedSeq = substr($sequence,$headerInfo{'start'}-1,$trimmedLen);
			print OF ">$headerInfo{'name'}\n$trimmedSeq\n"; 
		}
		
		if ($line =~ />/){
			my @lsplit = split(/\s/,$line);
			$lsplit[0] =~ />(.*)/;
			$headerInfo{'name'} = $1;
			$headerInfo{'start'} = $lsplit[4];
			$headerInfo{'stop'} = $lsplit[5];
		}
	}
	else {
		$sequence .= $line;
	}
	
}





sub varcheck {
	#print "f=$options{'f'}\n";
	if (!$opts{'f'}) {
		print "No filename provided.\n";
		&usage;
	}
}

sub usage{
	print STDERR "\nusage: perl \n";
	print STDERR "\n\n";
	print STDERR "\n";
	print STDERR "\n";
	print STDERR "\n\n";
	exit;
	
}