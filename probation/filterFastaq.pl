#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:l:cro:kh',\%opts); 

&varcheck;

my $outFile = $opts{'o'} || "-";
open (OUT,">$outFile") or die "Can't open $outFile\n";

my (@filterList,%filterHash,%lcFilterHash);
if (-e $opts{'l'}){
	open (FH,$opts{'l'}) or die "Can't open $opts{'l'}\n";
	@filterList = <FH>;
	chomp @filterList;
	close FH;
}
else {
	@filterList = split(/\s+/,$opts{'l'});
}
foreach my $f ( @filterList){
	$filterHash{$f}=1;
	$lcFilterHash{lc($f)}=1;
}
die "Can't find the filster list\n" if @filterList == 0;

open (FASTA,$opts{'f'}) or die "Can't open $opts{'f'}\n";
my $printFlag = 0;
while (my $fLine=<FASTA>){
	print "fline=$fLine";
	#next if $fLine =~ /^#/;
	next if $fLine =~ /^[\n\r]+$/;
	if ($fLine=~/^[>@](\S+)/){
		my $header=$1;
		if ($opts{'c'}){
			$header = lc ($header);
		}
		if ($opts{'r'}){
			foreach my $filtVal (@filterList){
				#my $caseVal = $opts{'c'} ? "i" : "";
				#if ($opts{'c'}){
					#$filtVal = lc ($filtVal);
				#}
				if ($opts{'c'}){
					if ($header =~ m/$filtVal/i){
						$printFlag = $opts{'k'} ? 1 : 0;
					}
					else{
						$printFlag = $opts{'k'} ? 0 : 1;
					}
				}
				else{
					if ($header =~ m/$filtVal/){
						$printFlag = $opts{'k'} ? 1 : 0;
					}
					else{
						$printFlag = $opts{'k'} ? 0 : 1;
					}
				}
			}
		}
		else{
			if ($opts{'c'}){
				if ($lcFilterHash{$header}){
					$printFlag = $opts{'k'} ? 1 : 0;
				}
				else{
					$printFlag = $opts{'k'} ? 0 : 1;
				}
					
			}
			else{
				if ($filterHash{$header}){
					$printFlag = $opts{'k'} ? 1 : 0;
				}
				else{
					$printFlag = $opts{'k'} ? 0 : 1;
				}
					
			}
		}
	}
	print OUT $fLine if $printFlag == 1;
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
	
	if (!$opts{'l'}){
		$errors .= "You have not provided a value for the -l flag\n";
	}
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName <-f file> <-l list|file> [-k -r -c]\n";
print <<PRINTTHIS;

Mandatory:
-f fasta input
-l list of filters in a file or from STDIN in format 'item1 item2'

Optional:
-o output file
-k (no input) Anything in the filter list will be kept.  Default is to discard anything in the filter list.
-r (no input) treats the filter list as a regex expression rather than text match
-c case insensitive match (Default is case sensitive)

Default behavior is to look for an exact match in the the text before any whitespace in each fasta header
Examples:
'>Thing1' will not be matched by 'thing1' because of default case sensitivity
'>Thing1' will be matched by 'thing1' only if the -c flag is used
'>thing1blah' will be matched by 'thing1' only if the -r flag is used
'>thing1blah extra' will not be matched by 'extra' because anything after the first whitespace char is ignored
	
	
PRINTTHIS
	exit;
}