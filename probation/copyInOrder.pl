#!/usr/bin/perl

#
# Phil Hatcher, March 2007
#
# Given a list of record names, find those records in a given FASTA file
# and output a new FASTA file to STDOUT with the records in the same order
# as in the input list.
# 

use strict;
use warnings;

if (@ARGV != 2)
{
  die "Usage: copyInOrder list-file fasta-file\n";
}

sub readInSeq
{
  # open the file
  my $fileName = $_[0];
  open(IN,"<", $fileName) or die "cannot open sequence input ($fileName)\n";

  # create a hash to return
  my %ret = ();

  # read first header line
  my $line;
  my $geneName = "";
  my $geneSeq = "";
  while ($line = <IN>)
  {
    if ($line =~ /^>/)
    {
      if (length($geneName) > 0)
      {
        $ret{$geneName} = $geneSeq;
      }
      $geneSeq = "";
      if ($line =~ /^>([^\s]+)/)
      {
        $geneName = $1;
      }
      else
      {
        chomp($line);
        die "can't parse header to get gene name ($line)\n";
      }
    }
    else
    {
      $geneSeq = $geneSeq . $line;
    }
  }
  if (length($geneName) > 0)
  {
    $ret{$geneName} = $geneSeq;
  }

  close(IN);

  return %ret;
}

# read FASTA file into a hash
my %fastaHash = readInSeq($ARGV[1]);

# open list file
open(LIST, "<", $ARGV[0]) or
  die "unable to open list file ($ARGV[0])\n";

while (my $line = <LIST>)
{
  chomp($line);

  my $seq = $fastaHash{$line};
  if (defined($seq))
  {
    print ">$line\n";
    print "$seq";
  }
  else
  {
    print STDERR "cannot find $line in FASTA input, so skipped\n";
  }
}
close(LIST);
