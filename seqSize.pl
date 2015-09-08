#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:s',\%opts);

if (!$opts{'f'}){
	&usage();
}

sub usage()
{
  print STDERR q(   Usage: seqsize -f fastafile [-s]
      Compute the sequence size of each sequence by counting residues of a fasta file.
      Output sent to standard output.

	  -s flag will print a sorted list of headers
  );
  exit;
}

my $seqFile = $opts{'f'};

open ( IN, $seqFile )  or die "Unable to open: ".$seqFile ;
my $basesCount=0;
my $header = "";
my %lengths;
while ( my $line = <IN> ) {
  next if $line =~ /#/;
  next if $line=~/^\s*$/;
  chomp $line;
  if ($line=~/>/){
    $line =~ s/>//;
    if ($basesCount>0){
      if ($opts{'s'}){
        $lengths{$header} = $basesCount;
      }
      else{
        print $header."\t".$basesCount."\n";
      }
      $basesCount = 0;
    }
    $header = $line;
  }
  else  {
    $basesCount += length( $line );
  }

}
if ($opts{'s'}){
  $lengths{$header} = $basesCount;
}
else{
  print $header."\t".$basesCount."\n";
}


if ($opts{'s'}){
  #my @balh = keys %lengths;
  #print join ("\n",@balh)."\n";
  my @sKeys = sort scaffSort (keys %lengths);
  foreach my $k (@sKeys){
    print "$k\t$lengths{$k}\n";
  }
}



sub scaffSort{
  $a=~/(\d+)/;
  my $aNum = $1;
  $b=~/(\d+)/;
  my $bNum = $1;
  return $aNum <=> $bNum;
  
}

