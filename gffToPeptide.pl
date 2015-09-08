#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('g:b:p:o:w:',\%opts); 
my $wayToProcess;

&varcheck;


my $cdsOut = $opts{'o'}."_cds.fna";
my $transOut = $opts{'o'}."_tscript.fna";
my $pepOut = $opts{'o'}.".faa";
open (CO,">$cdsOut") or die "Can't open $cdsOut\n";
open (PO,">$pepOut") or die "Can't open $pepOut\n";
if($wayToProcess == 1){
	open (TO,">$transOut") or die "Can't open $transOut\n";
}

#open (PO,">$pepOut") or die "Can't open $pepOut\n";
my $prefix = $opts{'p'} ? $opts{'p'} : "";
my %chromosomes;
my $chromSeq="";
my $chromNum;
my $firstLoop = 1;

my @blastDB = `fastacmd -D T -d $opts{'b'}`;
foreach my $line (@blastDB){
	chomp $line;
	if ($line=~/lcl\|(\S+)\s+/){
		if ($firstLoop == 0){
			$chromosomes{$chromNum}=$chromSeq;
		}
		my $chromName = $1;
		$chromName =~ /(\d+)/;
		$chromNum = $1;
		#print "\n>$chromNum\n";
		$chromSeq="";
		$firstLoop=0;
	}
	else{
		$chromSeq .= $line;
	}
	
}
$chromosomes{$chromNum}=$chromSeq;



open (GFF,$opts{'g'}) or die "Can't open $opts{'g'}\n";
my $prevGene="";
my $prevStrand = "";
my (@cdsArray,@tscriptArray);
my $parentType="";

while (my $line = <GFF>){
	chomp $line;
	next if $line =~ /^#/;
	#print "line=$line\n" if $prevGene eq "fgenesh1_pg.C_scaffold_8002211";
	my ($chrom,$source,$type,$start,$stop,$strand,$note) = (split(/\t/,$line))[0,1,2,3,4,6,8];
	my $id = $source; # will be replace later if way=1;
	$chrom=~/(\d+)/;
	$chromNum = $1;
	if ($type eq 'ncRNA' && $wayToProcess == 1){ # this is a kludge but it's good enough for now
		$parentType = 'ncRNA';
		next;
	}
	
	if($wayToProcess == 1){
		if ($type =~ /CDS/i || $type =~ /^TAS$/i || $type =~ /utr/i || 
			($parentType eq 'ncRNA' && $type=~/exon/)){
			if( $note=~/PARENT=([^;]+)/i){
				$id = $1;
			}
			elsif ($note =~ /name ([^;]+)/i){
				$id = $1;
			}
			elsif ($note =~ /Name=([^;]+)/i){
				$id = $1;
			}
			if ($id=~/,/i){
				$id = &cleanId($id);
			}
			
			if ($prevGene ne $id) {
				
				if ($prevGene ne ""){
					my @sortedCDS = sort{$$a[1]<=>$$b[1]} @cdsArray;
					my @sortedtrans = sort{$$a[1]<=>$$b[1]} @tscriptArray;
					my $cdsSeq = "";
					my $transSeq = "";
					foreach (@sortedCDS){
						$cdsSeq .= $_->[0];
					}
					foreach (@sortedtrans){
						$transSeq .= $_->[0];
					}
					$cdsSeq = revCmp($cdsSeq) if $prevStrand eq "-";
					$transSeq = revCmp($transSeq) if $prevStrand eq "-";
					print CO ">$prevGene\n$cdsSeq\n";
					print TO ">$prevGene\n$transSeq\n";
					my $peptide = &translate($cdsSeq);
					print PO ">$prevGene\n$peptide\n";
				
					@cdsArray = ();
					@tscriptArray = ();
				}
				my $seqSegment;
				
				my $offset = $start-1;
				my $len = $stop-$start+1;
				$seqSegment = substr($chromosomes{$chromNum},$offset,$len);
				$seqSegment =~ s/(>.*\n?)//;
				$seqSegment =~ s/\n//g;
				if ($type =~ /CDS/i || $type =~ /^TAS$/i){
					push (@cdsArray,[$seqSegment,$start]);
				}
				push (@tscriptArray,[$seqSegment,$start]);
				
			}
			
			else{
				my $seqSegment;
				my $offset = $start-1;
				my $len = $stop-$start+1;
				$seqSegment = substr($chromosomes{$chromNum},$offset,$len);
				$seqSegment =~ s/(>.*\n?)//;
				$seqSegment =~ s/\n//g;
				if ($type =~ /CDS/i || $type =~ /^TAS$/i){
					push (@cdsArray,[$seqSegment,$start]);
				}
				push (@tscriptArray,[$seqSegment,$start]);
				
			}
			
			
			$prevGene = $id;
			$prevStrand = $strand;
			#print "transcript=$cdsSeq\n";
	
		}
		else {
			$parentType = $type;
		}
	}
	else{
		my $seqSegment;
		my $offset = $start-1;
		my $len = $stop-$start+1;
		$seqSegment = substr($chromosomes{$chromNum},$offset,$len);
		$seqSegment = revCmp($seqSegment) if $strand eq "-";
		my $fHeader = $note;
		if ($note eq "." || $note=~/^[\s]*$/){
			$fHeader = "$id;$type;$start;$stop";
		}
		print CO ">$fHeader\n$seqSegment\n";
		my $peptide = &translate($seqSegment);
		print PO ">$fHeader\n$peptide\n";
	}
	
}

## print the last CDS
if ($wayToProcess == 1){
	my @sortedCDS = sort{$$a[1]<=>$$b[1]} @cdsArray;
	my @sortedtrans = sort{$$a[1]<=>$$b[1]} @tscriptArray;
	my $cdsSeq = "";
	my $transSeq = "";
	foreach (@sortedCDS){
		$cdsSeq .= $_->[0];
	}
	foreach (@sortedtrans){
		$transSeq .= $_->[0];
	}
	$cdsSeq = revCmp($cdsSeq) if $prevStrand eq "-";
	$transSeq = revCmp($transSeq) if $prevStrand eq "-";
	print CO ">$prevGene\n$cdsSeq\n";
	print TO ">$prevGene\n$transSeq\n";
	my $peptide = &translate($cdsSeq);
	print PO ">$prevGene\n$peptide\n";
}

sub cleanId{
	my $gffName = shift;
	my @splitName = split(",",$gffName);
	foreach my $sn (@splitName){
		$gffName = $sn if $sn!~/Protein/i;
	}

	return $gffName;
}
sub revCmp {
	my $seq = shift;
	$seq =~ tr/ACGTacgt/TGCAtgca/;
	$seq = reverse($seq);
	return $seq;
}

sub translate {
	my (%geneticCode) = (
		'TCA'=>'S', #Serine
		'TCC'=>'S', #Serine
		'TCG'=>'S',  #Serine
		'TCT'=>'S', #Serine
		'TTC'=>'F', #Phenylalanine
		'TTT'=>'F', #Phenylalanine
		'TTA'=>'L', #Leucine
		'TTG'=>'L', #Leucine
		'TAC'=>'Y', #Tyrosine
		'TAT'=>'Y', #Tyrosine
		'TAA'=>'*', #Stop
		'TAG'=>'*', #Stop
		'TGC'=>'C', #Cysteine
		'TGT'=>'C', #Cysteine
		'TGA'=>'*', #Stop
		'TGG'=>'W', #Tryptophan
		'CTA'=>'L', #Leucine
		'CTC'=>'L', #Leucine
		'CTG'=>'L', #Leucine
		'CTT'=>'L', #Leucine
		'CCA'=>'P', #Proline
		'CCC'=>'P', #Proline
		'CCG'=>'P', #Proline
		'CCT'=>'P', #Proline
		'CAC'=>'H', #Histidine
		'CAT'=>'H', #Histidine
		'CAA'=>'Q', #Glutamine
		'CAG'=>'Q', #Glutamine
		'CGA'=>'R', #Arginine
		'CGC'=>'R', #Arginine
		'CGG'=>'R', #Arginine
		'CGT'=>'R', #Arginine
		'ATA'=>'I', #Isoleucine
		'ATC'=>'I', #Isoleucine
		'ATT'=>'I', #Isoleucine
		'ATG'=>'M', #Methionine
		'ACA'=>'T', #Threonine
		'ACC'=>'T', #Threonine
		'ACG'=>'T', #Threonine
		'ACT'=>'T', #Threonine
		'AAC'=>'N', #Asparagine
		'AAT'=>'N', #Asparagine
		'AAA'=>'K', #Lysine
		'AAG'=>'K', #Lysine
		'AGC'=>'S', #Serine#Valine
		'AGT'=>'S', #Serine
		'AGA'=>'R', #Arginine
		'AGG'=>'R', #Arginine
		'GTA'=>'V', #Valine
		'GTC'=>'V', #Valine
		'GTG'=>'V', #Valine
		'GTT'=>'V', #Valine
		'GCA'=>'A', #Alanine
		'GCC'=>'A', #Alanine
		'GCG'=>'A', #Alanine
		'GCT'=>'A', #Alanine
		'GAC'=>'D', #Aspartic Acid
		'GAT'=>'D', #Aspartic Acid
		'GAA'=>'E', #Glutamic Acid
		'GAG'=>'E', #Glutamic Acid
		'GGA'=>'G', #Glycine
		'GGC'=>'G', #Glycine
		'GGG'=>'G', #Glycine
		'GGT'=>'G', #Glycine
	);

	my $seq = shift;
    
	my $peptide="";
	while ($seq){
		my $codon = substr($seq,0,3,"");
		$peptide .= $geneticCode{$codon} || "X";
	}
	return $peptide;
	
}


sub varcheck {
	my $errors = "";
	if (!$opts{'g'}) {
		$errors .= "gff file not provided\n";
	}
	elsif(!(-e $opts{'g'})) {
		$errors .= "Can't open $opts{'g'}\n";
	}
	
	if (!$opts{'b'}) {
		$errors .= "blastDb not provided\n";
	}
	
	
	if (!$opts{'o'}) {
		$errors .= "output file not provided\n";
	}
	
	if (!$opts{'w'}) {
		$wayToProcess = 1;
	}
	elsif($opts{'w'} != 2 && $opts{'w'} != 1){
		$errors .= "-w flag should be either 1 or 2\n";
	}
	else{
		$wayToProcess = $opts{'w'};
	}
	
	if ($errors ne "") {
		print $errors;
		&usage;
	}
}

sub usage{
	print STDERR <<END;

usage: perl gffToTranscript.pl -g gffFile -b blastDb -o outfile [-w] [-p prefix]
Converts a gff file to a set of transcript and peptide sequences

-g gff file to convert
-b blastDb of the whole genome
-o file for output.  Extensions of _cds.fna, _tscript.fna, and .faa will automatically be added.

-w way to process the gff file (1 or 2), defaults to 1:
   1:  gff contains CDS, UTR, and mRNA and/or gene lines.  CDS and UTR lines will be aggregated
       to make cds and transcripts.  Attributes of Name and Parent will be used as fasta headers
   2:  gff contains a feature on each line.  Each line will be turned into transcript
       and peptide with the attributes column used as the fasta header
-p prefix is the text before the chromosome number in the fasta file
	
END
exit;
}