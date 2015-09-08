#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use File::Copy;

my %opts;
getopts('d:',\%opts); 
my $dir = $opts{'d'} || "./";

&varcheck;

opendir(DIR,$dir) or die "Can't open $dir\n";
my @dirList = grep {/^[^\.]/ && -d "$dir/$_" } readdir(DIR);
rewinddir DIR;
my @fileList = grep{-f "$dir/$_" } readdir(DIR);
close DIR;
print join("\n",@dirList)."\n\n";
print join("\n",@fileList)."\n";

sub varcheck {
	my $errors = "";
	#if (!$opts{'d'}){
	#	$errors .= "-f flag not provided\n";
	#}
	#elsif(!(-e $opts{'f'})) {
	#	$errors .= "Can't open $opts{'f'}\n";
	#}
	
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName\n";
print <<PRINTTHIS;

Moves/Deletes/Copies files based on patterns entered into the script
	
PRINTTHIS
	exit;
}