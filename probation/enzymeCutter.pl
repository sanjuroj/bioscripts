#!/usr/bin/perl
#Way Sung 6/2006
# MUST CORRECT FIRST TWO LINES OF OUTPUT

sub usage()
{
   print STDERR q
   ( Usage: ecoR1split.pl <chromosomefile> <outFile> <cutSeq>
 
   );
   exit;
}

if ( ( @ARGV == 0 ) || $ARGV[0] eq "-h" )   #no arguments or help option
{
      &usage();
}

#Initialization of command line variables
my $chromosomeFile = $ARGV[0];
my $outFile = $ARGV[1];
my $seqInput = $ARGV[2];

#Initialization of list, fasta, destination file
open (SOURCE, "$chromosomeFile") || die "cant load file";
open (DEST, ">$outFile") || die "cant load file";

$/ = ">";
$| = 1;

while(<SOURCE>)
{
	chomp;
	my ($header, $sequence) = split(/\n/,$_,2);
	$sequence =~ s/[\n\r]//g;
	my $regexp = "($seqInput)";
	my $start = 0;
	my $seqlength = length($sequence);
	while ($sequence =~ /$regexp/ig)
	{
		$end = pos($sequence)-6;
		$len = $end-$start+1;
		
		print DEST ">", $header, "_", $start, "_", $end, "\n";
		print DEST substr($sequence, $start, $len), "\n";
		$start = $end+1;
	}	

	print DEST ">", $header, "_", $start, "_", $seqlength, "\n";
	$len = $seqlength-$start+1;
	print DEST substr($sequence, $start, $len), "\n";
}
