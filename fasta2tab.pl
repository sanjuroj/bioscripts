#!/usr/bin/perl

use strict;
use warnings;

my $firstFlag = 'yes';
while (<>) {
    my $line = $_;
    next if $line =~ /^\s*\n/;
    next if $line =~ /^\s*#/;
    chomp $line;
    if ($line =~ s/^>//) {
        if ($firstFlag eq 'no') {
          print "\n";
        }
        $firstFlag = 'no';
        print "$line\t";
    }
    else {
        print $line;
    }
    
    
}
print "\n";
