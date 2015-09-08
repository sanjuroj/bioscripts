#!/usr/bin/perl

use strict;
use warnings;
#use Cwd;

##### ##### ##### ##### #####

use Getopt::Std;
use vars qw( $opt_a $opt_b $opt_c $opt_v $opt_w);

# Usage
my $usage = "

sort_fasstq.pl - uses blat to sort fastq sequences into hits and misses.
                  
		      by
		Brian J. Knaus
		   May 2010

Copyright (c) 2010 Brian J. Knaus.
License is hereby granted for personal, academic, and non-profit use.
Commercial users should contact the author (http://brianknaus.com).

Great effort has been taken to make this software perform its said
task however, this software comes with ABSOLUTELY NO WARRANTY,
not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Usage: perl script.pl options
 required:
  -a	fastq input file.
  -b	reference fasta file.
 optional:
  -c	inset in nucleotides, used to remove barcodes [default = 0].
  -v	verbose mode [T/F, default is F].
  -w	delete intermediate (blat) files [T/F, default is T]

Verion 0.2.
";

# command line processing.
getopts('a:b:c:v:w:');
die $usage unless ($opt_a);
die $usage unless ($opt_b);

my ($infa, $ref, $inset, $nfile, $verb, $clean);
$infa	= $opt_a if $opt_a;
$ref	= $opt_b if $opt_b;
$inset	= $opt_c ? $opt_c : 0;
$verb	= $opt_v ? $opt_v : "F";
$clean	= $opt_w ? $opt_w : "T";

##### ##### ##### ##### #####
# Subfunctions.

# Check fastq file.
sub fastqchk{
  my $inf = shift;
  my @temp;
  my $in;
  # Check that file exists.
  if(-e $inf){} else {
    die "Error: $inf does not exist!\n";
  }
  open($in, "<", $inf) or die "Can't open $inf: $!";
  chomp($temp[0] = <$in>);	# First line is id.
  chomp($temp[1] = <$in>);	# Second line is sequence.
  chomp($temp[2] = <$in>);	# Third line is id.
  chomp($temp[3] = <$in>);	# Fourth line is quality.
  # Check identifier line.
  if($temp[0] !~ /^@/){
    print "Unexpected file format!\n";
    print "Line1: $temp[0]\n";
    print "Line2: $temp[1]\n";
    print "Line3: $temp[2]\n";
    print "Line4: $temp[3]\n";
    die "Error: Fastq file expected.\n";
  }
  # Check sequence.
  $_ = $temp[1];
  s/A//gi;
  s/C//gi;
  s/T//gi;
  s/G//gi;
  s/N//gi;
  if(length($_)>0){
    print "Unexpected file format!\n";
    print "Line1: $temp[0]\n";
    print "Line2: $temp[1]\n";
    print "Line3: $temp[2]\n";
    print "Line4: $temp[3]\n";
    die "Invalid character in sequence: $_.\n";
  }
  # Check identifier line.
  if($temp[2] !~ /^\+/){
    print "Unexpected file format!\n";
    print "Line1: $temp[0]\n";
    print "Line2: $temp[1]\n";
    print "Line3: $temp[2]\n";
    print "Line4: $temp[3]\n";
    die "Error: Fastq file expected.\n";
  }
  close $in or die "$in: $!";
}

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
  #
  my $outfa = outname($infa);
  #
  my ($ina, $out, $outna);
  my @temp;
  my ($counta);

  open($ina,  "<",  $infa)  or die "Can't open $infa: $!";
  open($out,  ">",  $outfa.".fa")  or die "Can't open $outfa.fa: $!";

  while (<$ina>){
    chomp($temp[0] = $_);	# First line is an id.
    chomp($temp[1] = <$ina>);	# Second line is a sequence.
    chomp($temp[2] = <$ina>);	# Third line is an id.
    chomp($temp[3] = <$ina>);	# Fourth line is quality.
    #

    # Prune first char.
    $temp[0] = substr($temp[0], 1);

    # Count Ns.
#    $counta = ($temp[1] =~ tr/N//);

    # Process Ns.
#    if ($counta >= 1){
#      $ns++;
#      if ($nfile eq "T"){
#        print $outna "@".$temp[0]."\n";
#        print $outna "$temp[1]\n";
#        print $outna "$temp[2]\n";
#        print $outna "$temp[3]\n";
#        #
#      }
#      next;
#    }

    # Print to fasta file.
    print $out ">$temp[0]\n";
    print $out "$temp[1]\n";
  }
  close $ina or die "$ina: $!";
  close $out or die "$out: $!";
}

sub blat {
  my $outf = shift;
  $outf = outname($outf);
  my $ref = shift;
  my $temp;
#  $temp = join("", "blat $ref $outf.fa ", $outf, "_blatout.psl -tileSize=6 -stepSize=1 -minScore=12 -noHead -fine -maxIntron=0");
  $temp = join("", "/local/cluster/bin/blat $ref $outf.fa ", $outf, "_blatout.psl -tileSize=6 -stepSize=1 -minScore=12 -noHead -fine -maxIntron=0");
#
#  $temp = join("", "blat $ref $outf.fa ", $outf, "_blatout.psl -tileSize=6 -stepSize=1 -minIdentity=90 -noHead -maxIntron=750000");
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
  my $outfa = outname($infa);
  my %blats;
  my @temp;
  my ($ina, $outa, $outma);

  # Generate hash of blat hits.
  @temp = blathash($infa);
  foreach(@temp){
    $blats{"$_"} = 0;
  }
  undef @temp;

  # Process fastq files.
  open( $ina, "<", $infa)  or die "Can't open $infa: $!";
  open( $outa, ">", $outfa."_hit.fq")  or die "Can't open ", $outfa, "_hit.fq: $!";
  open( $outma, ">", $outfa."_miss.fq")  or die "Can't open ", $outfa, "_miss.fq: $!";

  while (<$ina>){
    chomp($temp[0] = $_);	# First line is an id.
    chomp($temp[1] = <$ina>);	# Second line is a sequence.
    chomp($temp[2] = <$ina>);	# Third line is an id.
    chomp($temp[3] = <$ina>);	# Fourth line is quality.

    if (exists $blats{substr($temp[0], 1)}){
      # Print to fastq file.
      # Hits.
      print $outa "$temp[0]\n";
      print $outa "$temp[1]\n";
      print $outa "$temp[2]\n";
      print $outa "$temp[3]\n";
    } else {
      # Print to fastq file.
      # Misses.
      print $outma "$temp[0]\n";
      print $outma "$temp[1]\n";
      print $outma "$temp[2]\n";
      print $outma "$temp[3]\n";
    }
  }

  close $ina or die "$ina: $!";
  close $outa or die "$outa: $!";
  close $outma or die "$outma: $!";
}

sub clean {
  my $infa = shift;
  my $outf = outname($infa);
  unlink $outf.".fa";
  unlink $outf."_blatout.psl";
}


##### ##### ##### ##### #####
# Globals.

##### ##### ##### ##### #####
# Main.

# Check file format.
fastqchk($infa);

# Create a fasta file for input to blat.
fastq2fasta($infa);

# Call blat.
blat($infa, $ref);

# Create sorted files.
sortfile($infa);

# Clean up temp files.
if ($clean eq "T"){
  clean($infa);
}

##### ##### ##### ##### #####
# EOF.
