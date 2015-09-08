#!/usr/bin/perl

use strict;
use warnings;

##### ##### ##### ##### #####

use Getopt::Std;
use vars qw( $opt_a $opt_b $opt_c $opt_d $opt_v $opt_w);

# Usage
my $usage = "

sort_fasstq_pe.pl - uses blat to sort paired-end fastq sequences into hits and misses.
                  
		      by
		Brian J. Knaus
		   July 2010

Copyright (c) 2010 Brian J. Knaus.
License is hereby granted for personal, academic, and non-profit use.
Commercial users should contact the author (http://brianknaus.com).

Great effort has been taken to make this software perform its said
task however, this software comes with ABSOLUTELY NO WARRANTY,
not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Usage: perl script.pl options
 required:
  -a	fastq input file a.
  -b	fastq input file b.
  -c	reference fasta file.
 optional:
  -d	create a file containing reads with Ns [default = F].
  -v	verbose mode [T/F, default is F].
  -w	delete intermediate (blat) files [T/F, default is T].

version 0.001.

";

# command line processing.
getopts('a:b:c:d:v:w:');
die $usage unless ($opt_a);
die $usage unless ($opt_b);
die $usage unless ($opt_c);

my ($infa, $infb, $ref, $nfile, $verb, $clean);
$infa	= $opt_a if $opt_a;
$infb	= $opt_b if $opt_b;
$ref	= $opt_c if $opt_c;
$nfile	= $opt_d ? $opt_d : "F";
$verb	= $opt_v ? $opt_v : "F";
$clean	= $opt_w ? $opt_w : "T";

##### ##### ##### ##### #####
# Globals.

#my ($outfa, $outfb);
my @blats;

##### ##### ##### ##### #####
# Main.

# Create a fasta file for input to blat.
fastq2fasta($infa, $infb, $nfile);

# Call blat.
blat($infa, $ref);

# Create hash of blat hits.
#@blats = blathash($infa);

# Create sorted files.
sortfile($infa, $infb);

# Clean up temp files.
if ($clean eq "T"){
  clean($infa);
}


##### ##### ##### ##### #####
# Subfunctions.

sub outname {
  my $inf = shift;
  my @temp = split("/", $inf);
  $inf = $temp[$#temp];
  @temp = split(/\./, $inf);
  my $outf = $temp[0];
  return($outf);
}

sub fastq2fasta {
  my $infa = shift;
  my $infb = shift;
  my $nfile = shift;
  #
  my $outfa = outname($infa);
  my $outfb = outname($infb);
  #
  my ($ina, $inb, $out, $outna, $outnb);
  my @temp;
  my ($counta, $countb);

  open($ina,  "<",  $infa)  or die "Can't open $infa: $!";
  open($inb,  "<",  $infb)  or die "Can't open $infb: $!";
  open($out,  ">",  $outfa.".fa")  or die "Can't open $outfa.fa: $!";

#  if ($nfile eq "T"){
#    open( $outna,  ">",  $outfa."_Ns.fq")  or die "Can't open ".$outfa."_Ns.fq: $!";
#    open( $outnb,  ">",  $outfb."_Ns.fq")  or die "Can't open ".$outfb."_Ns.fq: $!";
#  }

  while (<$ina>){
    chomp($temp[0] = $_);	# First line is an id.
    chomp($temp[1] = <$ina>);	# Second line is a sequence.
    chomp($temp[2] = <$ina>);	# Third line is an id.
    chomp($temp[3] = <$ina>);	# Fourth line is quality.
    #
    chomp($temp[4] = <$inb>);	# First line is an id.
    chomp($temp[5] = <$inb>);	# Second line is a sequence.
    chomp($temp[6] = <$inb>);	# Third line is an id.
    chomp($temp[7] = <$inb>);	# Fourth line is quali

    # Prune first char.
    $temp[0] = substr($temp[0], 1);
    $temp[4] = substr($temp[4], 1);

    # Count Ns.
#    $counta = ($temp[1] =~ tr/N//);
#    $countb = ($temp[5] =~ tr/N//);

    # Process Ns.
#    if ($counta >= 1 || $countb >= 1){
#      $ns++;
#      if ($nfile eq "T"){
#        print $outna "@".$temp[0]."\n";
#        print $outna "$temp[1]\n";
#        print $outna "$temp[2]\n";
#        print $outna "$temp[3]\n";
        #
#        print $outnb "@".$temp[4]."\n";
#        print $outnb "$temp[5]\n";
#        print $outnb "$temp[6]\n";
#        print $outnb "$temp[7]\n";
#      }
#      next;
#    }

    # Print to fasta file.
    print $out ">$temp[0]\n";
    print $out "$temp[1]\n";
    print $out ">$temp[4]\n";
    print $out "$temp[5]\n";
  }

  close $ina or die "$ina: $!";
  close $inb or die "$inb: $!";
  close $out or die "$out: $!";

#  if ($nfile eq "T"){
#    close $outna or die "$outna: $!";
#    close $outnb or die "$outnb: $!";
#  }
}

sub blat {
  my $outf = shift;
  $outf = outname($outf);
  my $ref = shift;
  my $temp;
  $temp = join("", "blat $ref $outf.fa ", $outf, "_blatout.psl -tileSize=6 -stepSize=1 -minScore=12 -noHead -fine -maxIntron=0");
  #print "blatcmd = $temp\n";
  system $temp;
}

sub blathash {
  my $outf = shift;
  $outf = outname($outf);
  my $in;
  my @temp;
  my %blats;
  open( $in,  "<",  $outf.'_blatout.psl')  or die "Can't open ", $outf, "_blatout.psl: $!";
  while (<$in>){
    @temp = split(/\t/);
    $blats{$temp[9]} = 0;
  }
  close $in or die "$in: $!";
  return(keys(%blats));
}

sub sortfile {
  my $infa = shift;
  my $infb = shift;
  my $outfa = outname($infa);
  my $outfb = outname($infb);
  my %blats;
  my @temp;
  my ($ina, $inb, $outa, $outb, $outma, $outmb);

  # Generate hash of blat hits.
  @temp = blathash($infa);
  foreach(@temp){
    $blats{"$_"} = 0;
  }
  undef @temp;

  # Process fastq files.
  open( $ina, "<", $infa)  or die "Can't open $infa: $!";
  open( $inb, "<", $infb)  or die "Can't open $infb: $!";
  open( $outa, ">", $outfa."_hit.fq")  or die "Can't open ", $outfa, "_hit.fq: $!";
  open( $outb, ">", $outfb."_hit.fq")  or die "Can't open ", $outfb, "_hit.fq: $!";
  open( $outma, ">", $outfa."_miss.fq")  or die "Can't open ", $outfa, "_miss.fq: $!";
  open( $outmb, ">", $outfb."_miss.fq")  or die "Can't open ", $outfb, "_miss.fq: $!";

  while (<$ina>){
    chomp($temp[0] = $_);	# First line is an id.
    chomp($temp[1] = <$ina>);	# Second line is a sequence.
    chomp($temp[2] = <$ina>);	# Third line is an id.
    chomp($temp[3] = <$ina>);	# Fourth line is quality.
    #
    chomp($temp[4] = <$inb>);	# First line is an id.
    chomp($temp[5] = <$inb>);	# Second line is a sequence.
    chomp($temp[6] = <$inb>);	# Third line is an id.
    chomp($temp[7] = <$inb>);	# Fourth line is quality.

    # Discard Ns.
#    if ($temp[1] =~ /[Nn\.]/ || $temp[5] =~ /[Nn\.]/){
#      next;
#    }
		substr($temp[0],1) =~ /([^\s]+)/;
		my $headercomp = $1;
		
    if (exists $blats{$headercomp}){
      # Print to fastq file.
      # Hits.
      print $outa "$temp[0]\n";
      print $outa "$temp[1]\n";
      print $outa "$temp[2]\n";
      print $outa "$temp[3]\n";
      #
      print $outb "$temp[4]\n";
      print $outb "$temp[5]\n";
      print $outb "$temp[6]\n";
      print $outb "$temp[7]\n";
    } else {
      # Print to fastq file.
      # Misses.
      print $outma "$temp[0]\n";
      print $outma "$temp[1]\n";
      print $outma "$temp[2]\n";
      print $outma "$temp[3]\n";
      #
      print $outmb "$temp[4]\n";
      print $outmb "$temp[5]\n";
      print $outmb "$temp[6]\n";
      print $outmb "$temp[7]\n";
    }
  }

  close $ina or die "$ina: $!";
  close $inb or die "$inb: $!";
  close $outa or die "$outa: $!";
  close $outb or die "$outb: $!";
  close $outma or die "$outma: $!";
  close $outmb or die "$outmb: $!";
}

sub clean {
  my $infa = shift;
  my $outf = outname($infa);
  unlink $outf.".fa";
  unlink $outf."_blatout.psl";
}

##### ##### ##### ##### #####
# EOF.
