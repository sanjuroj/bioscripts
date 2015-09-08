#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use File::Spec;

my %opts;
getopts('d:h',\%opts); 

&varcheck;

opendir(my $dh, $opts{'d'}) || die "Can't open directory";
while (my $filename = readdir $dh) {
		next if $filename =~ /read/i;
		next if $filename !~ /\.txt$/;
		
		my $defline = $filename;
		$defline =~ s/\.txt//;
		
		my $seq = "";
		open(my $fh,File::Spec->catfile($opts{'d'},$filename));
		foreach my $line (<$fh>) {
			next if $line =~ /^\s*#/;
			chomp $line;
			next if $line =~/^\s+$/;
			
			$line =~ s/[\s\t\d]//g;
			$seq .= $line;
		}
		print ">$defline\n$seq\n";
		
		
}
closedir $dh;


sub varcheck {
	&usage if ($opts{'h'});
	my $errors = "";
	if (!$opts{'d'}){
		$errors .= "You have not provided a value for the -d flag\n";
	}
	elsif(!(-d $opts{'d'})) {
		$errors .= "Can't open $opts{'d'}\n";
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

Concatenates individual sequence files that are in non-fasta format.  The title of the file will be used for the seqeunce definition.
	
PRINTTHIS
	exit;
}