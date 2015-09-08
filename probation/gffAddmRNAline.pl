#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
#use vars qw($opt_f);

my %opts;
getopts('f:',\%opts); 

&varcheck;

open (FH,$opts{'f'}) or die "Can't open $opts{'f'}\n";
my @lines = <FH>;
close FH;
chomp @lines;
my ($beforeStop,$afterStop);
my $prevName = "";
my $prevStop = 0;
my @printLines;
foreach my $line (@lines){
	my @spl = split (/\t/,$line);
	#print "pn=$prevName, cur=$spl[1]\n";
	if ($prevName eq ""){
		$beforeStop = "$spl[0]\t$spl[1]\tmRNA\t$spl[3]\t";
		$afterStop = "\t.\t$spl[6]\t.\t$spl[8]\n";
		$printLines[0] = $line;
		$prevName = $spl[1];
		$prevStop = $spl[4];
		next;
	}
	
	if ($spl[1] ne $prevName) {
		print $beforeStop.$prevStop.$afterStop;
		foreach (@printLines){
			print $_."\n";
		}
		$beforeStop = "$spl[0]\t$spl[1]\tmRNA\t$spl[3]\t";
		$afterStop = "\t.\t$spl[6]\t.\t$spl[8]\n";
		@printLines = ();
		$printLines[0] = $line;
		$prevName = $spl[1];
		$prevStop = $spl[4];
	}
	else {
		$printLines[@printLines] = $line;
		$prevStop = $spl[4];
	}
	
}
print $beforeStop.$prevStop.$afterStop;
foreach (@printLines){
	print $_."\n";
}




sub varcheck {
	my $errors = "";
	if (!$opts{'f'} || !(-e $opts{'f'})) {
		$errors .= "Input file hasn't been entered or doesn't exist\n";
	}
	
	if ($errors ne "") {
		print $errors;
		&usage;
	}
}

sub usage{
	print STDERR "\nusage: perl gffAddmRNAline.pl <-f gffFile>  \n";
	print STDERR "\n\n";
	print STDERR "\n";
	print STDERR "\n";
	print STDERR "\n\n";
	exit;
	
}