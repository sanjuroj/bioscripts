#!/usr/bin/perl
use strict;
#-------------------------------------------------------#
#-------------------------------------------------------#

sub usage()
{
   print STDERR q
   ( Usage: copySeqByPos.pl <seqFile>
   
   Describes how many N's are in a FASTA sequence.  Outputs length of the sequence, number of N's,
   and the % of N's.
   );
   exit;
}

if ( ( @ARGV != 1 ) || $ARGV[0] eq "-h" )   #no arguments or help option
{
      &usage();
}


#Initialization of command line variables
my $seqFile = $ARGV[0];

#Initialization of source and destination file, printing headers in destination file
open (SEQ, "$seqFile") || die "cant load file";

my $n=0;

$/ = ">";										#input operator (starts slurp)
$| = 1;											#buffer clear (for large data sets)

my $line = <SEQ>;
print "seqID\tseqLen\tnumNs\tpercentNs\n";
$/ = ">";
while(<SEQ>)
{
	my ($header, $sequence) = split(/\n/,$_,2);	#split into two list variables    
    #my ($seqid) = $header =~ /^(\S+)/;                      #set the ssr ID to the first whitespace delimited
	$sequence =~ s/[\n\r]//g;   				#concatenates sequence at newline/return
	#print "\nheader=$header\nsequence\n$sequence\n";
	
	my $Ncount = $sequence =~ s/N/N/g;
	my $Npercent = $Ncount/length($sequence);
	print "$header\t".length($sequence)."\t$Ncount\t$Npercent\n";
	
	#$beg = $sequence =~ /^(N+)/;
	#$mid = $sequence =~ /$(N+)/;
	#$end = $sequence =~ /(N+)/;
	
}
