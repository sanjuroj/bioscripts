#!/usr/bin/perl

use strict;
use warnings;

if (! (-e $ARGV[0])) {
	print "The file doesn't exist";
}
my $cmd;
$cmd = 'perl -i -pe \'s/\r\n/\n/g\' '.$ARGV[0];
`$cmd`;
$cmd = 'perl -i -pe \'s/\r/\n/g\' '.$ARGV[0];
`$cmd`;

