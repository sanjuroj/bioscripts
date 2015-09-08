#!/usr/bin/perl
use strict;
use Getopt::Std;

my %opts;
getopts('g:o:n', \%opts);

if (!$opts{'g'}) {
   print "No gff file has been provided (-g flag is mandatory)\n";
   &usage;
}
elsif (!(-e $opts{'g'})){
   print STDERR "The file $opts{'g'} does not exist\n";
   &usage;
}

my $outFile = $opts{'o'} || "-";
open (OUT,">$outFile") or die "Can't open $outFile\n";

my (@genes,%allLines,$header);
open (FILE,$opts{'g'}) or die "Can't open $opts{'g'}\n";
while (my $line = <FILE>){
   next if $line=~/^[\n\r\s]+$/;
   $header .= $line if $line =~/^#/;
   if ($line =~/ID=([^,;\n]+)/i){
	  push (@genes,$line);
	  push (@{$allLines{$1}},$line);
	  #print "ID=$1\n";
   }
   if ($line =~/Parent=([^,;\n]+)/i){
	  push (@{$allLines{$1}},$line);
	  #print "count=".@{$allLines{$1}}."\n";
	  #print "Parent=$1\n";
   }
}

close FILE;

my %typeOrder = qw(gene 1 pseudogene 2 mRNA 3 pseudogenic_transcript 4 exon 5 CDS 6);

print OUT $header;
@genes = sort msort (@genes);
foreach my $geneLine (@genes){
   $geneLine =~ /ID=([^,;\n]+)/;
   my $gName = $1;
   my @lines = @{$allLines{$gName}};
   #print "linecount=".@lines."\n";
   @lines = sort msort (@lines);
   #print OUT "gname=$gName, lines=".@lines."\n";
   print OUT join("",@lines);
}
#print STDERR @genes;
#exit;


#my @orderedGff = sort msort @lines;

#my @tempFile = split(/./,$ARGV[0]);
#my $oFile = $tempFile[0],"_sorted.gff";
#print $oFile;

#print OUT @orderedGff;


##########################################################################
# Begin Subroutines
##########################################################################

sub msort{
   my $aComment = $a=~/^#/ ? 1 : -1;
   my $bComment = $b=~/^#/ ? 1 : -1;
   
   my ($aScaf, $aTypeText, $aStart, $aStrand) = (split(/\t/,$a))[0,2,3,6];
   my ($bScaf, $bTypeText, $bStart, $bStrand) = (split(/\t/,$b))[0,2,3,6];
   if ($opts{'n'}){
	  $aScaf=~s/[^\d]+//g;
	  $bScaf=~s/[^\d]+//g;
   }
   
   my $aType = $typeOrder{$aTypeText} ? $typeOrder{$aTypeText} : 20;
   my $bType = $typeOrder{$bTypeText} ? $typeOrder{$bTypeText} : 20;
   
   $aStrand = $aStrand eq "+" ? 1 : -1;
   $bStrand = $bStrand eq "+" ? 1 : -1;
   
   $bComment <=> $aComment || $aScaf <=> $bScaf || $aStart <=> $bStart || $aType <=> $bType || $aStrand <=> $bStrand;
    
}

sub usage()
{
   print STDERR q
(
Usage: snapSort.pl <gff File> 

THIS SCRIPT SORT OF WORKS BUT NOT FOR COMPLICATED GFF FILES.  NEEDS SOME WORK.
Does a multifield sort on a .gff file.

Sorts in the following order:  scaffold/chromosome, start position, type, strand (+ > -).
Scaffold/Chromosome will be sorted alphabetically (should work fine with numbers unt).
Type is sorted as follows:
[#comments] > [gene|pseudogene] > [mRNA|pseudogenic_transcript] > [exon|CDS] > [all other]

Blank lines will not be printed.

ONLY WORKS IF ALL LINES HAVE EITHER ID OR PARENT TAGS.  This is necessary to keep genes in blocks.
Sorting just by position doesn't work when genes overlap.


Required:
-g  Gff file

Optional:
-n  (flag) Tries to sort chomosomes numerically by stripping all non-numeric characters from the field
-o  file.  Output file.  Default is STDOUT
	
	
);
   exit;
}

