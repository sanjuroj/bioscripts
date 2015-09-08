#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
#use vars qw($opt_f);

my %opts;
getopts('f:',\%opts); 

&varcheck;

my $blastDb = "/home/mcb/jogdeos/carrington/mir_evolution/arabTargetComp/blastDB/A.thaliana.chroms.fna.unmsk";
my $chromText = "ath";

open (FH, $opts{'f'}) or die "Can't open $opts{'f'}";


for (my $line = <FH>) {
	chomp $line;
	my $seq;
	my ($name,$chrom,$strand,$start,$end) = split(/\t/,$line);
	my $sVal = $strand == -1 ? 2 : 1;
	my $chromID = $chromText.$chrom;
	my $cmd = "fastacmd -d $blastDb -s $chromID -L ".$start.",".$end;
	my $output .= `$cmd`;
	$output =~ s/>lcl\|/>/;
	$output =~ s/(>\S+) .*/$1_$name/;
	print $output;
}






sub varcheck {
	my $errors = "";
	if (!$opts{'f'} || !(-e $opts{'f'})) {
		$errors .= "\n";
	}
	
	if ($errors ne "") {
		print $errors;
		&usage;
	}
}

sub usage{
	print STDERR "\nusage: perl run_fastacmd -f coordFile\n";
	print STDERR "\nRuns fastacmd.\n";
	print STDERR "-f filename should be tab separated columns:  \n";
	print STDERR "name, chromosome, strand (1 or -1), start, stop.\n";
	print STDERR "\n\n";
	exit;
	
}