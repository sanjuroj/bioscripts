#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:p:o:s:a:h',\%opts); 

&varcheck;

my $prefix = $opts{'p'} || "gene";
my $outfile = $opts{'o'} || "-";

open (FH,$opts{'f'});
open (OH,">$outfile");
my $counter = 1;
my %nameMap;
my %nameConvert;
if ($opts{'s'}) {
	%nameConvert = &readNameSubs($opts{'s'});
}
my @nameOrder;
foreach my $line (<FH>) {
  if ($line=~/^>/){
    chomp $line;
    $line =~ s/^>//;
		push (@nameOrder,$line);
		
		my $newName;
		if ($opts{'s'}) {
			if ($nameConvert{$line}) {
				$newName = $nameConvert{$line};
			}
			else {
				$newName = $prefix.sprintf('%06d',$counter);
				$counter++;
			}
		}
		else {
			$newName = $prefix.sprintf('%06d',$counter);
			$counter++;
		}
    
    $nameMap{$line} = $newName;
    print OH ">$newName\n";
    
  }
  else {
    print OH $line;
  }

}

open (LOG,">nameMap.txt");
foreach my $oldName (@nameOrder) {
  print LOG "$oldName\t$nameMap{$oldName}\n";
}


sub readNameSubs {
	my $filename = shift;
	open (IN,$filename);
	my %retHash;
	foreach my $line (<IN>) {
		chomp $line;
		my($old,$new) = split("\t",$line);
		$retHash{$old} = $new;
	}
	return %retHash;
	
}



sub varcheck {
	&usage if ($opts{'h'});
	my $errors = "";
	if (!$opts{'f'}){
		$errors .= "You have not provided fasta file with the -f flag\n";
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
	
	print "\nusage: perl $scriptName <-f> [-o] [-p -s] \n";
print <<PRINTTHIS;

Renames a fasta file.  If only the -p flag is used, a sequential number will be used.

-p text  specifies the header name prefix.  Default = "gene"
-s filename  substitution file.  Tab delim file with existing name in col 1 and new name in col 2.
     If a match is not found, it will revert to using a name with a prefix and a sequential number.
-a integer  pad the sequential numbering with 0's.  Default = 0.
-o filename  output file name
	
PRINTTHIS
	exit;
}
