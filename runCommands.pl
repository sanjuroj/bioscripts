#!/usr/bin/perl
use strict;
use warnings;
use File::Find;


find (\&wanted,$ARGV[0]);





sub wanted {
  if (-f $_) {

    my $cmd = "head $_";
    print "Running this command: $cmd\n";
    my $result = `$cmd`;
    print "The result is: $result\n";
  








  }




}
