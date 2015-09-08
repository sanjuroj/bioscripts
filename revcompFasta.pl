#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('hrc',\%opts); 

&varcheck;


my $input = $ARGV[0] || "-";
open (my $fh,$input);

foreach my $line (<$fh>) {
    processLine($line);
}


sub processLine {
    my $line = shift;
    if ($line =~ /^>/) {
        chomp $line;
        $line=~/([^\s]+)(.*)/;
        print "$1_rc$2\n";
    }
    else{
        chomp $line;
        if (!$opts{'c'}) {
            $line =reverse($line);    
        }
        if (!$opts{'r'}) {
            $line =~ tr/ACGT/TGCA/;    
        }
        
        print $line."\n";
        
    }
}    



sub varcheck {
	&usage if ($opts{'h'});
	
	&usage if (-t STDIN && not $ARGV[0]);


=begin
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
=cut
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName <-f file>\n";
print <<PRINTTHIS;

Reverse complements a sequence.  Accepts input from STDIN or a file.

-r (optional) only reverses a file or sequence
-c (optional) only complements a file or sequence
	
PRINTTHIS
	exit;
}
