#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
#use vars qw($opt_f);

my %opts;
getopts('f:b:',\%opts); 

&varcheck;

open (FH, $opts{'f'}) or die "Can't open $opts{'f'}";
my @genes = <FH>;
close FH;

my %gHash;
foreach my $line (@genes){
	chomp $line;
	my @test = split("\t",$line);
	my $group = $test[0];
	if (@test > 1){
		$group = $test[1];
	}
	
	push (@{$gHash{$group}},$test[0]);
}
@genes = ();

foreach my $k (keys %gHash){
	my @geneGroup = @{$gHash{$k}};
	open (OUT,">$k") or die "Can't open $k\n";
	foreach my $g (@geneGroup) {
		my $cmd = "fastacmd -d $opts{'b'} -s $g";
		my $output .= `$cmd`;
		$output =~ s/>lcl\|/>/;
		$output =~ s/(>\S+) .*/$1/;
		print OUT $output;
	}
	close OUT;
}


sub varcheck {
	my $errors = "";
	if (!$opts{'f'}){
		$errors .= "You did not specify a gene file with -f\n";
	}
	elsif(!(-e $opts{'f'})) {
		$errors .= "Can't open $opts{'f'}\n";
	}
	if (!$opts{'b'}){
		$errors .= "You did not specify a blastDB with -b\n";
	}
	
	if ($errors ne "") {
		print "\n".$errors;
		&usage;
	}
}

sub usage{
	$0=~/^[\.\/]*(\S+)/;
	my $scriptName = $1;
	print STDERR "\nusage: perl $scriptName <-f file> <-b blastDB>\n";
print STDERR<<END;

Runs fastacmd on file of gene names. Output will be to separate fasta files for each gene.
Genes can optionally be grouped by indicating a group id in the second column,
in which case fasta formatted sequences will be grouped in files.  For the grouped
option, output filenames will be the group id.  If any genes are grouped, all genes must have a
group id.

-f genefile, gene name in col1 and optional groupid in col2
-b blast database 

	
END
	
	exit;
	
}