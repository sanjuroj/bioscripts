#!/usr/bin/perl

use strict;
use warnings;
#use Cwd;
use Cwd 'abs_path';
use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;
use IO::Compress::Gzip qw(gzip $GzipError) ;

##### ##### ##### ##### #####

use Getopt::Std;
use vars qw( $opt_a $opt_b $opt_c $opt_d $opt_s $opt_m $opt_v);

# Usage
my $usage = "
bcsort_pe - Sort barcodes from a pair of fastq files.
		      by
		Brian J. Knaus
		  August 2011

Copyright (c) 2010, 2011 Brian J. Knaus.
License is hereby granted for personal, academic, and non-profit use.
Commercial users should contact the author (http://brianknaus.com).

Great effort has been taken to make this software perform its said
task however, this software comes with ABSOLUTELY NO WARRANTY,
not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Usage: perl bcsort_pe.pl options
 required:
  -a	fastq input file a.
  -b	fastq input file b.
 optional:
  -c	barcode file name, no quotes, one barcode per line
	[optional, default = barcodes.txt].
  -d	output directory [optional, default is bcsort_out].
  -s	output fasta file [default is T].
  -m	output fastq file [default is T].
  -n	files are gzipped [default is T].
  -v	verbose mode [optional T/F, default is F].

Version 0.1-1

";

# command line processing.
getopts('a:b:c:d:s:m:v:');
die $usage unless ($opt_a);
die $usage unless ($opt_b);

my ($infa, $infb, $bcfile, $outdir, $fa, $fq, $verb);

$infa	= $opt_a if $opt_a;
$infb	= $opt_b if $opt_b;
$bcfile	= $opt_c ? $opt_c : "barcodes.txt"; 
$outdir	= $opt_d ? "bcsort_out".$opt_d :"bcsort_out";
$fa	= $opt_s ? $opt_s : "T";
$fq	= $opt_m ? $opt_m : "T";
$verb	= $opt_v ? $opt_v : "F";

##### ##### ##### ##### #####
# Globals.

my $bclog = "00_bcsort_log.txt";
my ($in, $out, @temp);
my (%barcodesH, %bcnames, @barcodesA);
my ($anom1, $anom2);

##### ##### ##### ##### #####
# Main.

# Get absolute path of infiles.
$infa = abs_path($infa);
$infb = abs_path($infb);
$bcfile = abs_path($bcfile);
$outdir = abs_path($outdir);

# Create outdir.
mkdir($outdir);
chdir($outdir);

# Check infile is a valid fastq.
fastqchk($infa);
fastqchk($infb);

# Initialize log.
open($out, ">", $bclog) or die "Can't open $bclog: $!";
print $out $usage;
print $out "\n      ----- ----- --*-- ----- -----\n\n";
print $out "Infile a:\t$infa\n";
print $out "Infile b:\t$infb\n";
print $out "Barcodes file:\t$bcfile\n";
print $out "Out directory:\t$outdir\n";
print $out "Print fasta:\t$fa\n";
print $out "Print fastq:\t$fq\n";
print $out "Verbose:\t$verb\n";
print $out "\n      ----- ----- --*-- ----- -----\n\n";
close $out or die "$out: $!";

# Initial timestmp.
my @stime = localtime(time);
timestamp($bclog, 'Process started');

##### ##### ##### ##### #####
# Input barcodes.
timestamp($bclog, 'Processing barcodes');
open($in,  "<",  $bcfile)  or die "Can't open $bcfile: $!";

while (<$in>){
  chomp;
  @temp = split("\t", $_);
  $barcodesH{uc($temp[0])} = 0;
  $bcnames{uc($temp[0])} = $temp[1];
  push @barcodesA, uc($temp[0]);
}
@barcodesA = sort(@barcodesA);

open($out, ">>", $bclog) or die "Can't open $bclog: $!";
print $out "Barcodes:\n\n";
foreach(@barcodesA){
  print $out "$_\t=>\t";
  print $out $bcnames{$_}."\n";
}
print $out "\n      ----- ----- --*-- ----- -----\n\n";
close $out or die "$out: $!";

##### ##### ##### ##### #####
# Input data and sort
# into a hash of arrays.
#
# Keys are barcodes.
# Values are arrays of samples.

timestamp($bclog, 'Reading in data');

my ($ina, $inb, $anom);
open($ina,  "<",  $infa)  or die "Can't open $infa: $!";
open($inb,  "<",  $infb)  or die "Can't open $infb: $!";
open($anom1,  ">",  "anomalous_reads1.txt")  or die "Can't open anomalous_reads1: $!";
open($anom2,  ">",  "anomalous_reads2.txt")  or die "Can't open anomalous_reads2: $!";

my ($ida, $bca, $seqa, $prba, $idb, $bcb, $seqb, $prbb);
my $anom_num = 0;
my $bc_num = 0;
my $ntot = 0;
my %samps;

# Read in.
while (<$ina>){
  $ntot = $ntot + 1;

  # Read a.
  chomp($ida	= $_);
  $ida = substr $ida,1;
  chomp($seqa	= <$ina>);
  <$ina>;
  chomp($prba	= <$ina>);

  # Read b.
  chomp($idb	= <$inb>);
  $idb = substr $idb,1;
  chomp($seqb	= <$inb>);
  <$inb>;
  chomp($prbb	= <$inb>);

#  my @test = ('AACT', 'ACCAAT', 'TGACTT');
#  my $test = join("|",@test);
  my $test = join("|",@barcodesA);
  my @matches1 = ($seqa =~ /^($test)/o);
  my @matches2 = ($seqb =~ /^($test)/o);
  if ($#matches1 == 0){
    # Sequence one matches a barcode.
    if($#matches2 ==0 && $matches1[0] eq $matches2[0]){
      # Sequence two matches the same barcode as sequence one.
      @temp = debarcode($matches1[0],$ida,$seqa,$prba);
      $ida = $temp[0];
      $seqa = $temp[1];
      $prba = $temp[2];
      @temp = debarcode($matches1[0],$idb,$seqb,$prbb);
      $idb = $temp[0];
      $seqb = $temp[1];
      $prbb = $temp[2];
      push @{$samps{$matches1[0]}}, join("\t", $ida, $seqa, $prba, $idb, $seqb, $prbb); # Hash of arrays.
      $barcodesH{$matches1[0]} = $barcodesH{$matches1[0]} + 1;
      $bc_num = $bc_num + 1;
    }elsif($#matches2 < 0){
      # Sequence one matches a barcode, sequence two doesn't.
      @temp = debarcode($matches1[0],$ida,$seqa,$prba);
      $ida = $temp[0];
      $seqa = $temp[1];
      $prba = $temp[2];
      @temp = debarcode(substr($seqb,0,length($matches1[0])),$idb,$seqb,$prbb);
      $idb = $temp[0];
      $seqb = $temp[1];
      $prbb = $temp[2];
      push @{$samps{$matches1[0]}}, join("\t", $ida, $seqa, $prba, $idb, $seqb, $prbb); # Hash of arrays.
      $barcodesH{$matches1[0]} = $barcodesH{$matches1[0]} + 1;
      $bc_num = $bc_num + 1;
    } else {
      # Anomalous reads.
      $anom_num = $anom_num + 1;
    }
  } elsif ($#matches2 == 0 && $#matches1 < 0){
    # Sequence two matches a barcode, sequence one doesn't.
    @temp = debarcode(substr($seqa,0,length($matches2[0])),$ida,$seqa,$prba);
    $ida = $temp[0];
    $seqa = $temp[1];
    $prba = $temp[2];
    @temp = debarcode($matches2[0],$idb,$seqb,$prbb);
    $idb = $temp[0];
    $seqb = $temp[1];
    $prbb = $temp[2];
    push @{$samps{$matches2[0]}}, join("\t", $ida, $seqa, $prba, $idb, $seqb, $prbb); # Hash of arrays.
    $barcodesH{$matches2[0]} = $barcodesH{$matches2[0]} + 1;
    $bc_num = $bc_num + 1;
  } else {
    # All other reads are anomalous.
    # Read a.
    print $anom1 "\@$ida\n";
    print $anom1 "$seqa\n";
    print $anom1 "+$ida\n";
    print $anom1 "$prba\n";
    # Read b.
    print $anom2 "\@$idb\n";
    print $anom2 "$seqb\n";
    print $anom2 "+$idb\n";
    print $anom2 "$prbb\n";
    #
    $anom_num = $anom_num + 1;
  }
  if ($ntot % 1000000 == 0){
    open($out, ">>", $bclog) or die "Can't open $bclog: $!";
    print $out $ntot/1000000, "\tmillion records sorted.\n";
    close $out or die "$out: $!";
  }
}

close $ina or die "$ina: $!";
close $inb or die "$inb: $!";
close $anom1 or die "$anom1: $!";
close $anom2 or die "$anom2: $!";

# Report to log.
open($out, ">>", $bclog) or die "Can't open $bclog: $!";
print $out "\n";
close $out or die "$out: $!";
timestamp($bclog, 'Data read and sorted');

##### ##### ##### ##### #####
# Write data to file.

# Report to log.
timestamp($bclog, 'Writing data to file');

# fasta files.
if ($fa eq "T"){
  foreach $bca (keys %samps) {
    open($out, ">",  $bca."_seq.fa") or die "Can't open output.txt: $!";
    foreach ( @{$samps{$bca}}){
      @temp = split("\t",$_);
      print $out ">$temp[0]\n";
      print $out "$temp[1]\n";
      print $out ">$temp[3]\n";
      print $out "$temp[4]\n";
    }
    close $out or die "$out: $!";
  }
  # Report to log.
  timestamp($bclog, 'Fasta files written');
}

# Fastq files.
if ($fq eq "T"){
  foreach $bca (keys %samps) {
    open($out, ">",  $bca."_seq1.fq") or die "Can't open ".$bca."_seq1.fq: $!";
    open(my $out2, ">",  $bca."_seq2.fq") or die "Can't open ".$bca."_seq2.fq: $!";
    foreach ( @{$samps{$bca}}){
      @temp = split("\t",$_);
      print $out "\@$temp[0]\n";
      print $out $temp[1], "\n";
      print $out "+$temp[0]\n";
      print $out "$temp[2]\n";
      print $out2 "\@$temp[3]\n";
      print $out2 $temp[4], "\n";
      print $out2 "+$temp[3]\n";
      print $out2 $temp[5], "\n";
    }
    close $out or die "out: $!";
    close $out2 or die "out2: $!";
  }
  # Report to log.
  timestamp($bclog, 'Fastq files written');
}

# Report to log.
timestamp($bclog, 'Data written to file');

##### ##### ##### ##### #####
# Summary.

open($out, ">>", $bclog) or die "Can't open $bclog: $!";

#print $out "\n      ----- ----- --*-- ----- -----\n\n";
print $out "\nTotal reads:\t\t";
print $out $ntot / 1000000, "\tmillion";
print $out "\nBarcoded reads:\t\t";
print $out $bc_num / 1000000, "\tmillion";
print $out "\nNon-barcoded reads:\t";
print $out ($ntot - $bc_num) / 1000000, "\tmillion (total-barcoded)";
print $out "\nAnomalous reads:\t";
print $out $anom_num / 1000000, "\tmillion";

print $out "\n\n";

print $out "Barcode Summary:\n\n";
#while (my($key, $value) = each %barcodes){
#	print $log "$key \t=>\t", $value/1000000, "\tmillion", "\n";
#}
foreach (@barcodesA){
  print $out "$_\t=>\t".$barcodesH{$_}."\t=>\t".$bcnames{$_}."\n";
}
#print $out "\n      ----- ----- --*-- ----- -----\n\n";

close $out or die "$out: $!";

##### ##### ##### ##### #####
# Finish.

open($out, ">>", $bclog) or die "Can't open $bclog: $!";
print $out "\n      ----- ----- --*-- ----- -----\n\n";
print $out "Process initiated:\t";
print $out $stime[4]+1;
print $out "-$stime[3]-";
print $out $stime[5]+1900;
#print $out $year+1900;
print $out " $stime[2]:$stime[1]:$stime[0]\n";
close $out or die "$out: $!";

# Log finish time.
timestamp($bclog, 'Process finished');

open($out, ">>", $bclog) or die "Can't open $bclog: $!";
print $out "bcsort process complete.\n\n";
close $out or die "$out: $!";

##### ##### ##### ##### #####
# Subfunctions,

sub idbc {
	# id tab bc as input.
	my @id = split(/\#|\//, shift);
	my $bca = shift;
	$id[1] = $bca;
	return join("", $id[0], "\#", $id[1], "/", $id[2]);
}

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
  s/.//gi;
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

sub timestamp{
  my $logf = shift;
  my $msg = shift;
  my $out;

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

  open($out, ">>", $logf) or die "Can't open $logf: $!";
  print $out $msg.":\t";
  print $out $mon+1;
  print $out "-".$mday."-";
  print $out $year+1900;
  print $out " $hour:$min:$sec\n";
  print $out "\n      ----- ----- --*-- ----- -----\n\n";
  close $out or die "$out: $!";
}

sub debarcode{
  my $bcode = shift;
  my $id = shift;
  my $seq = shift;
  my $prb = shift;
  my $mach;
  my @temp;

  my $bclength = length($bcode);
  $seq = substr $seq, $bclength;
  $prb = substr $prb, $bclength;
  @temp = split /[\/#]/, $id;
  $id = "$temp[0]#$bcode/$temp[2]";

  return($id, $seq, $prb);
#      @temp = debarcode($_,$ida,$seqa,$prba);

}


##### ##### ##### ##### #####
# EOF.
