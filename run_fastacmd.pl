#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:o:',\%opts); 

&varcheck;

#print "flag=$opts{'f'}\n";
#my $test = `fastacmd $opts{'f'}`;
#print "test:\n$test\n";

my $output = "";
my $firstFlag = 1;
foreach my $line (split("\n",`fastacmd $opts{'f'}`)){
	next if $line =~ /^[\n\r]+$/;
	next if $line =~ /^\s*#/;
	chomp $line;
	if ($line=~/^>lcl\|(\S+)\s/){
		$output .= "\n" if $firstFlag != 1;
		$output .= ">$1\n";
		$firstFlag = 0;
	}
	else {
		$output .= $line;
	}
}
if ($opts{'o'}){
	open (OUT,">$opts{'o'}") or die "Can't open $opts{'ol'}\n";
	print OUT $output."\n";
}
else{
	print "$output\n";	
}


sub varcheck {
	my $errors = "";
	if (!$opts{'f'}){
		$errors .= "-f flag not provided\n";
	}
	
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName -f \"flags\" [-o output file]\n";
print <<PRINTTHIS;

Runs fastacmd with a list of fastacmd flags in quotes.  Lazy way of removing
the extra text that fastacmd seems to need to add, as well as make single line fasta files.
	
PRINTTHIS
	exit;
}