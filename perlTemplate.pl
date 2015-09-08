#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:h',\%opts); 

&varcheck;



sub varcheck {
	&usage if ($opts{'h'});
	my $errors = "";
	if (!$opts{'f'}){
		$errors .= "You have not provided a value for the -f flag\n";
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
	
	print "\nusage: perl $scriptName <-f file>\n";
print <<PRINTTHIS;

I want to print stuff
	
PRINTTHIS
	exit;
}