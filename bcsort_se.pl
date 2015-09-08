#!/usr/bin/perl

use strict;
use warnings;
use Cwd 'abs_path';
#use Cwd;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;
use IO::Compress::Gzip qw(gzip $GzipError) ;
use File::Spec;
#use File::Path qw(make_path remove_tree);

##### ##### ##### ##### #####

use Getopt::Std;
use vars qw( $opt_a $opt_c $opt_d $opt_e $opt_f $opt_g $opt_s $opt_m $opt_v);

# Usage
my $usage = "
bcsort_se.pl - sorts barcodes from fastq.gz files.
		      by
		Brian J. Knaus
		  July 2011

Copyright (c) 2010, 2011 Brian J. Knaus.
License is hereby granted for personal, academic, and non-profit use.
Commercial users should contact the author (http://brianknaus.com).

Great effort has been taken to make this software perform its said
task however, this software comes with ABSOLUTELY NO WARRANTY,
not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Usage: perl bcsort_se.pl options
 required:
  -a	fastq.gz file.
 optional:
  -c	barcode file name, no quotes, one barcode per line
	[optional, default = barcodes.txt].
  -d	postfix for output directory [optional, default is null
        resulting in outdir = bcsort_out].
  -e	output directory.
  -f	fastq file is gzipped [default is T].
  -g	filter reads [default is F].
  -s	output fasta file [default is T].
  -m	output fastq file [default is T].
  -v	verbose mode [optional T/F, default is F].

Version 0.1-1.

";

# command line processing.
getopts('a:c:d:e:f:g:s:m:v:');
die $usage unless ($opt_a);

my ($infa, $bcfile, $outdir, $outpath, $zip, $filter, $fa, $fq, $verb);

$infa	= $opt_a if $opt_a;
$bcfile	= $opt_c ? $opt_c : "barcodes.txt"; 
$outdir	= $opt_d ? "bcsort_out".$opt_d :"bcsort_out";
$outpath	= $opt_e ? $opt_e : "";
$zip	= $opt_f ? $opt_f : "T";
$filter	= $opt_g ? $opt_g : "F";
$fa	= $opt_s ? $opt_s : "F";
$fq	= $opt_m ? $opt_m : "T";

$verb	= $opt_v ? $opt_v : "F";

##### ##### ##### ##### #####
# Globals.

#my ($in, $outf, $out);

my $bclog = "00_bcsort_log.txt";
my ($in, $ina);
my $anom1;
my $anoma = "anomalous_reads1.fastq.gz";
my ($out, $outa);
my @temp;
my (%barcodesH, %bcnames, @barcodesA);
my $bc_regex;
my @stime;

##### ##### ##### ##### #####
# Main.

# Check infile is a valid fastq.
fastqchk($infa, $zip);

# Get absolute path of infiles.
$infa = abs_path($infa);
$bcfile = abs_path($bcfile);
$outpath = abs_path($outpath);

# Manage file names.
$outdir = File::Spec->catfile($outpath, $outdir);
$bclog = File::Spec->catfile($outdir, $bclog);
$anoma = File::Spec->catfile($outdir, $anoma);
if($outdir !~ /\/$/){$outdir = $outdir."/";}

# Create outdir.
mkdir($outdir);

##### ##### ##### ##### #####
# Initialize log.

open($out, ">", $bclog) or die "Can't open $bclog: $!";
print $out $usage;
print $out "\n      ----- ----- --*-- ----- -----\n\n";
print $out "Infile a:\t$infa\n";
print $out "Barcodes file:\t$bcfile\n";
print $out "Out directory:\t$outdir\n";
print $out "Out path:\t$outpath\n";
print $out "Print fasta:\t$fa\n";
print $out "Print fastq:\t$fq\n";
print $out "Verbose:\t$verb\n";
print $out "\n      ----- ----- --*-- ----- -----\n\n";
close $out or die "$out: $!";

# Initial timestmp.
@stime = localtime(time);
timestamp($bclog, 'Process started');

##### ##### ##### ##### #####
# Input barcodes.

timestamp($bclog, 'Processing barcodes');
open($in,  "<",  $bcfile)  or die "Can't open $bcfile: $!";

while (<$in>){
  chomp;
  @temp = split("\t", $_);
  $barcodesH{uc($temp[0])} = 0;
  if($#temp == 0){
    $bcnames{uc($temp[0])} = 'NA';
  } else {
    $bcnames{uc($temp[0])} = $temp[1];
  }
  push @barcodesA, uc($temp[0]);
}
@barcodesA = sort(@barcodesA);
$bc_regex = join(")|(", @barcodesA)."\n";
  chomp($bc_regex);
$bc_regex = "((".$bc_regex."))";

open($out, ">>", $bclog) or die "Can't open $bclog: $!";
print $out "Barcodes:\n\n";
foreach(@barcodesA){
  print $out "$_\t=>\t";
  print $out $bcnames{$_}."\n";
}
print $out "\n";
print $out "Regex:\n";
print $out "$bc_regex\n";
print $out "\n      ----- ----- --*-- ----- -----\n\n";
close $out or die "$out: $!";

##### ##### ##### ##### #####
# Input data and sort
# into a hash of arrays.
#
# Keys are barcodes.
# Values are arrays of samples.

timestamp($bclog, 'Reading in data');

if($zip eq 'T'){
  $ina = new IO::Uncompress::Gunzip $infa or die "IO::Uncompress::Gunzip failed: $GunzipError\n";
  $anom1 = new IO::Compress::Gzip $anoma or die "IO::Compress::Gzip failed: $GzipError\n";
} else {
  open($ina,  "<",  $infa)  or die "Can't open $infa: $!";
  open($anom1,  ">",  $anoma)  or die "Can't open anomalous_reads1: $!";
}

my ($ida, $bca, $seqa, $prba);
my $anom_num = 0;
my $bc_num = 0;
my $ntot = 0;
my $freads = 0;
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

  # Filter reads?
  @temp = split(/\s/, $ida);
  @temp = split(/:/, $temp[1]);
  if(($temp[1] eq 'Y') && ($filter eq 'T')){
    # Filtered read, do nothing.
    $freads = $freads +1;
  } else {
    if($seqa =~ /^$bc_regex/){
      if(defined $2){
        open($out, ">", $bclog) or die "Can't open $bclog: $!";
        print $out "Oh oh! More than one barcode matched. This should never happen.\n";
        print $out "$1\t$2\t$seqa\n";
        close $out or die "$out: $!";
      }

      @temp = debarcode($1,$ida,$seqa,$prba);
      $ida = $temp[0];
      $seqa = $temp[1];
      $prba = $temp[2];
      push @{$samps{$1}}, join("\t", $ida, $seqa, $prba); # Hash of arrays.
      $barcodesH{$1} = $barcodesH{$1} + 1;
      $bc_num = $bc_num + 1;
#  }
    } else {
      # All other reads are anomalous.
      print $anom1 "\@$ida\n";
      print $anom1 "$seqa\n";
#      print $anom1 "+$ida\n";
      print $anom1 "+\n";
      print $anom1 "$prba\n";
      #
      $anom_num = $anom_num + 1;
    }
  }
}

if($zip eq 'T'){
  close $ina or die "$ina: $GunzipError\n";
  close $anom1 or die "$anom1: $GzipError\n";
} else {
  close $ina or die "$ina: $!";
  close $anom1 or die "$anom1: $!";
}


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
    $outa = $outdir.$bca.".fasta.gz";
    if($zip eq 'T'){
      $out = new IO::Compress::Gzip $outa or die "IO::Compress::Gzip failed: $GzipError\n";
    } else {
      open($out, ">",  $outa) or die "Can't open output.txt: $!";
    }
      foreach ( @{$samps{$bca}}){
        @temp = split("\t",$_);
        print $out ">$temp[0]\n";
        print $out "$temp[1]\n";
      }
    if($zip eq 'T'){
      close $out or die "$out: $GzipError\n";
    } else {
      close $out or die "$out: $!";
    }
  }
  # Report to log.
  timestamp($bclog, 'Fasta files written');
}

# Fastq files.
if ($fq eq "T"){
  foreach $bca (keys %samps) {
    $outa = $outdir.$bca.".fastq.gz";
    if($zip eq 'T'){
      $out = new IO::Compress::Gzip $outa or die "IO::Compress::Gzip failed: $GzipError\n";
    } else {
      open($out, ">",  $outa) or die "Can't open $outa: $!";
    }
    foreach ( @{$samps{$bca}}){
      @temp = split("\t",$_);
      print $out "\@$temp[0]\n";
      print $out $temp[1], "\n";
      print $out "+\n";
      print $out "$temp[2]\n";
    }
    if($zip eq 'T'){
      close $out or die "$out: $GzipError\n";
    } else {
      close $out or die "out: $!";
    }
  }
  # Report to log.
  timestamp($bclog, 'Fastq files written');
}

# Report to log.
timestamp($bclog, 'Data written to file');

##### ##### ##### ##### #####
# Summary.

open($out, ">>", $bclog) or die "Can't open $bclog: $!";

print $out "\nTotal reads:\t\t";
print $out $ntot / 1000000, "\tmillion";
print $out "\nBarcoded reads:\t\t";
print $out $bc_num / 1000000, "\tmillion";
print $out "\nNon-barcoded reads:\t";
print $out ($ntot - $bc_num) / 1000000, "\tmillion (total-barcoded)";
print $out "\nFiltered reads:\t\t";
print $out $freads / 1000000, "\tmillion";
print $out "\nAnomalous reads:\t";
print $out $anom_num / 1000000, "\tmillion";

print $out "\n\n";

print $out "Barcode Summary:\n\n";
foreach (@barcodesA){
  print $out "$_\t=>\t".$barcodesH{$_}."\t=>\t".$bcnames{$_}."\n";
}

close $out or die "$out: $!";

##### ##### ##### ##### #####
# Finish.

open($out, ">>", $bclog) or die "Can't open $bclog: $!";
print $out "\n      ----- ----- --*-- ----- -----\n\n";
print $out "Process initiated:\t";
print $out $stime[4]+1;
print $out "-$stime[3]-";
print $out $stime[5]+1900;
print $out " $stime[2]:$stime[1]:$stime[0]\n";
close $out or die "$out: $!";

# Log finish time.
timestamp($bclog, 'Process finished');

open($out, ">>", $bclog) or die "Can't open $bclog: $!";
print $out "bcsort process complete.\n\n";
close $out or die "$out: $!";

##### ##### ##### ##### #####
# Subroutines.              #
##### ##### ##### ##### #####

# Check fastq file.
sub fastqchk{
  my $inf = shift;
  my $zip = shift;
  my @temp;
  my $in;
  # Check that file exists.
  if(-e $inf){} else {
    die "Error: $inf does not exist!\n";
  }

  if($zip eq 'T'){
    $in = new IO::Uncompress::Gunzip $inf or die "IO::Uncompress::Gunzip failed: $GunzipError\n";
  } else {
    open($in, "<", $inf) or die "Can't open $inf: $!";
  }
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
  if($zip eq 'T'){
    close $in or die "$in: $GunzipError\n";
  } else {
    close $in or die "$in: $!";
  }
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
  my $bc = shift;
  my $ida = shift;
  my $seqa = shift;
  my $prba = shift;

  my $q = substr($prba, 0, length($bc));
  $seqa = substr($seqa, length($bc));
  $prba = substr($prba, length($bc));
  $ida = $ida.$bc.':'.$q; # Not sure this is standard.
  return($ida,$seqa,$prba);
}

##### ##### ##### ##### #####
# EOF.
