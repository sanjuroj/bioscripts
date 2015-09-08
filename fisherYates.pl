#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:o:n:h',\%opts); 

&varcheck;

open (FH,$opts{'f'}) or die "Can't open $opts{'f'}\n";
my @lines = <FH>;
close FH;
my $num = $opts{'n'} || @lines;

if ($num > @lines){
	print STDERR "You've selected more lines than are in the file.  Returning all.\n";
}


&fisher_yates_shuffle(\@lines);

my $outfile = $opts{'o'} || "-";
open (OUT,">$outfile") or die "Can't open $outfile\n";
for my $i (0..$num-1){
	print OUT $lines[$i];
}





sub fisher_yates_shuffle {
	my $seqs = shift;
	my $x;
	for ($x = @$seqs; --$x; ) {
		my $y = int(rand($x+1));
		next if $x == $y;
		@$seqs[$x,$y] = @$seqs[$y,$x];
	}
}


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
	
	print "\nusage: perl $scriptName <-f file> [-o outfile]\n";
print <<PRINTTHIS;

Performs a Fisher-Yates shuffle on a list and returns the specified number of lines.

Mandatory:
-f file.  A list of whatever.

Optional
-n integer.  Number of lines to return.  Default is all.
-o filename.  Optional output file.  Default is STDOUT.


	
PRINTTHIS
	exit;
}