#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:h',\%opts); 

&varcheck;

open(FH,$opts{'f'});
my @cList = <FH>;
close FH;

my $counter = 0;
for my $clone (@cList) {
    chomp $clone;
    next if $clone =~ /^IS/;
    if ($counter % 3 == 0) {
        sleep(1);
    }
    #my $cmd = "esearch -db unigene -query $clone | elink -target nucest | efetch -format fasta >> fallCloneSeqs.fasta";
    my $cmd = "esearch -db unigene -query $clone";
    print $cmd."\n";
    my $cmdout = `$cmd`;
    
   
   
   
    last if $counter > 3;
    $counter++;
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
	
	print "\nusage: perl $scriptName <-f file>\n";
print <<PRINTTHIS;

Get sequence for list of clones from NCBI.

Must provide the list with the -f flag
	
PRINTTHIS
	exit;
}