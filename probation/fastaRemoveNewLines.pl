#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
#use vars qw($opt_f);

my %opts;
getopts('f:',\%opts); 

&varcheck;

open (FA,$opts{'f'});
my $firstLine = 1;
while (my $line = <FA>){
	if ($line =~ />/) {
		if ($firstLine == 0) {
			print "\n";
		}
		else {
			$firstLine = 0;
		}
		print $line;
	}
	else {
		chomp $line;
		print $line;
	}
}
print "\n";





sub varcheck {
	if (!$opts{'f'} || !(-e $opts{'f'})) {
		print STDERR "\nYou did not provide a file\n";
		&usage;
	}
}

sub usage{
	print STDERR "\nusage: perl \n";
	print STDERR "\nConverts a fasta file where the sequence is in multiple lines\n";
	print STDERR "to one where the sequence is in just one line\n";
	exit;
	
}