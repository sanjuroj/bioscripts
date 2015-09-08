#!usr/bin/perl;

use strict;

my $blastFile = $ARGV[0];
open (BFILE,$blastFile);
open (ANIT,">blastANIT");
open (ANIS,">blastANIS");
open (ANIU,">blastANIU");
my $counter=0;

while (my $line=<BFILE>){
	#print $line;
	if ($line =~ m/(ANIS)/){
		print ANIS $line; 
	}
	elsif ($line =~ m/(ANIT)/){
		print ANIT $line;
	}
	elsif ($line =~ m/(ANIU)/){
		print ANIU $line;
	}
	else{
		$counter++;
	}
}

print "counter=$counter\n";

