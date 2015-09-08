#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:o:c:p:g:',\%opts); 

&varcheck;

#my $cdsSource = "/raid3/carrington/jogdeos/carrington/genomes/lyrata/allAlyGenes_cds.fna";
#my $pepSource = "/raid3/carrington/jogdeos/carrington/genomes/lyrata/allAlyGenes.faa";
#my $gffSource = "/raid3/carrington/jogdeos/carrington/genomes/lyrata/allAlyGenes.gff3";
my $cdsSource = $opts{'c'};
my $pepSource = $opts{'p'};
my $gffSource = $opts{'g'};

my $outBase = $opts{'o'} || $opts{'f'};
my $gffOut = "$outBase.gff3";
my $pepOut = "$outBase.faa";
my $cdsOut = "$outBase\_cds.fna";

open (PEP,$pepSource) or die "Can't open $pepSource\n";
open (CDS,$cdsSource) or die "Can't open $cdsSource\n";
open (CO,">$cdsOut") or die "Can't open $cdsOut for writing\n";
open (PO,">$pepOut") or die "Can't open $pepOut for writing\n";
open (GO,">$gffOut") or die "Can't open $gffOut for writing\n";
my @gffLines = `cat $gffSource`;
my @list = `cat $opts{'f'}`;



my %found;
my $processCount=1;


print STDOUT "Processing peptide file\n";
my $printFlag = 0;
while (my $line = <PEP>){
	next if $line =~ /^[\n\r]+$/;
	if ($line =~/>/){
		print STDERR "$processCount....\r" if $processCount % 1000 == 0;
		$processCount++;
		my $foundFlag = 0;
		foreach my $gene (@list){
			chomp $gene;
			if ($line =~ /^>$gene$/){
				print PO $line;
				$printFlag = 1;
				$found{$gene}->{'pep'} = 1;
				$foundFlag += 1;
			}
		}
		if ($foundFlag > 1){
			print STDERR "\nAlready found a gene for pep Line: FATAL\n";
			print STDERR $line;
			die;
		}
		elsif ($foundFlag == 1){
			$printFlag = 1;
		}
		else{
			$printFlag = 0;
		}
	}
	else{
		print PO $line if $printFlag == 1;
	}
}
print STDERR "\n";

$processCount=1;
print STDOUT "Processing CDS file\n";
$printFlag = 0;
while (my $line = <CDS>){
	next if $line =~ /^[\n\r]+$/;
	if ($line =~/>/){
		print STDERR "$processCount....\r" if $processCount % 1000 == 0;
		$processCount++;
		my $foundFlag = 0;
		foreach my $gene (@list){
			chomp $gene;
			if ($line =~ /^>$gene$/){
				print CO $line;
				$printFlag = 1;
				$found{$gene}->{'cds'} = 1;
				$foundFlag += 1;
			}
		}
		if ($foundFlag > 1){
			print STDERR "Already found a gene for this CDS Line: FATAL";
			print STDERR $line;
			die;
		}
		elsif ($foundFlag == 1){
			$printFlag = 1;
		}
		else{
			$printFlag = 0;
		}
	}
	else{
		print CO $line if $printFlag == 1;
	}
}
print STDERR "\n";


my @gffOut;
print STDOUT "Processing gff file\n";
foreach my $gene (@list){
	chomp $gene;
	my @grepped = grep(/=$gene[,;\n\s]/,@gffLines);
	my @grepTest = grep(/JCC_20110402_2[,;\n\s]/,@gffLines);
	#print "gffsource=$gffSource\n";
	#print "count=".@grepTest."\n";
	#print "found in $gene:\n".join("",@grepTest)."\n" if @grepTest > 0;
	if (@grepped > 1){
		$found{$gene}->{'gff'} = 1;
		@gffOut = (@gffOut,@grepped);
	}
	
}

@gffOut = sort gffSort @gffOut;

print GO "##gff-version\t3\n";
print GO join("",@gffOut);


my $notFoundCount=0;
foreach my $gene (@list){
	if (!$found{$gene}){
		print STDERR "Couldn't fine anything for $gene\n";
		$notFoundCount++;
	}
	else{
		print "No match for $gene gff\n" if !$found{$gene}->{'gff'};
		print "No match for $gene pep\n" if !$found{$gene}->{'pep'};
		print "No match for $gene cds\n" if !$found{$gene}->{'cds'};
		if (keys %{$found{$gene}} < 3){
			$notFoundCount++;
		}
			
	}
}
print STDERR "All genes found\n" if $notFoundCount == 0;


close PO;
close GO;
close CO;
close PEP;
close CDS;

my $pepCount = () = `grep ">" $pepOut`;
print "Peptide Gene Count=$pepCount\n";
my $cdsCount = () = `grep ">" $cdsOut`;
print "CDS Gene Count=$cdsCount\n";
my $gffCount = () = `grep mRNA $gffOut`;
print "gff Gene Count=$gffCount\n";




sub gffSort{
	my @aArray = split("\t",$a);
	my @bArray = split("\t",$b);
	return $aArray[0] cmp $bArray[0] || $aArray[3]<=>$bArray[3] || $bArray[4] <=> $aArray[4]; # sort by scaff then start
	#return $aArray[0] gt $bArray[0]; # sort by scaff then start
}



sub varcheck {
	my $errors = "";
	if (!$opts{'f'}){
		$errors .= "-f flag not provided\n";
	}
	elsif(!(-e $opts{'f'})) {
		$errors .= "Can't open $opts{'f'}\n";
	}
	
	if (!$opts{'c'}){
		$errors .= "-c flag not provided\n";
	}
	elsif(!(-e $opts{'c'})) {
		$errors .= "Can't open $opts{'c'}\n";
	}
	
	if (!$opts{'g'}){
		$errors .= "-g flag not provided\n";
	}
	elsif(!(-e $opts{'g'})) {
		$errors .= "Can't open $opts{'g'}\n";
	}
	
	if (!$opts{'p'}){
		$errors .= "-p flag not provided\n";
	}
	elsif(!(-e $opts{'p'})) {
		$errors .= "Can't open $opts{'p'}\n";
	}
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName <-f file> <-c,-p,-g files> [-o base name]\n";
print <<PRINTTHIS;

Takes a list of genes and builds gff, peptide and cds files from the list.
Outputs a list of genes not found to STDOUT.

This would be easier to do with grep but it is harder to get a list of things that
were not found in the sourcefiles with grep.  Perl scripts was written to ensure
that the whole list was found.

-f file containing a list of genes
-o base name for output files.  Will create .faa, _cds.fna, and .gff files.  If -o
	flag not provided, will use -f input.
-c cds source
-p peptide source
-g gff source
	
PRINTTHIS
	exit;
}
