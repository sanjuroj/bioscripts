#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:hr:o:',\%opts); 

&varcheck;

my $of = $opts{'o'} || "-";
open (RF,$opts{'r'}) or die "Can't open $opts{'r'}\n";
open (OUT, ">$of") or die "Can't open $opts{'o'}\n";
my %replacements;
while (my $line = <RF>){
	chomp $line;
	my ($target,$repl) = split("\t",$line);
	$replacements{$target} = $repl;
}
close RF;
#foreach (keys %replacements){
#	print "$_=$replacements{$_}\n";
#}
open (TF,$opts{'f'}) or die "Can't open $opts{'f'}\n";
while (my $line = <TF>){
	chomp $line;
	foreach my $target (keys %replacements){
		my $sub = $replacements{$target};
		#my $oldLine = $line;
		$line =~ s/\Q$target\E/$sub/g;
		
		#if($line =~ s/^\Q$target\E\t/$sub\t/ ||
		   #$line =~ s/>\Q$target\E/>$sub/){
			#last;	
		#}
		   
	}
	print OUT "$line\n";
}
close TF;



sub varcheck {
	&usage if ($opts{'h'});
	my $errors = "";
	if (!$opts{'f'}){
		$errors .= "-f flag not provided\n";
	}
	elsif(!(-e $opts{'f'})) {
		$errors .= "Can't open $opts{'f'}\n";
	}
	if (!$opts{'r'}){
		$errors .= "-r flag not provided\n";
	}
	elsif(!(-e $opts{'r'})) {
		$errors .= "Can't open $opts{'r'}\n";
	}
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName <-f file> <-r file>\n";
print <<PRINTTHIS;

Replaces names in a file.

-f Target File
-r tab delimited name file with name to replace in the first column and replacement in second.
-o (optional) filename for output file


PRINTTHIS
	exit;
}