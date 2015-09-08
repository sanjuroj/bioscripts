#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use File::Temp;

my %opts;
getopts('s:g:mo:d',\%opts); 


&varcheck;

my $outDir = $opts{'o'};
$outDir=~s/\/$//;
die "Can't find the $outDir directory\n" if (!(-d $outDir));

my $groupListing="";

print STDERR "Loading Fasta files...\n";
my ($seqHash,$seqOrder) = loadFasta($opts{'s'});
#my ($nucHash,$nucOrder) = loadFasta($opts{'n'});
print STDERR "Done loading Fasta files\n";
my %orthoList;
if ($opts{'g'}){
	open (ORTHOS,$opts{'g'}) or die "Can't open $opts{'g'}\n";
	while (my $line = <ORTHOS>){
		next if $line=~/^#/;
		next if $line=~/^[\s\n\r]+$/;
		chomp $line;
		my ($gene,$orthoGroup) = split(/\t/,$line);
		if (!(defined $gene)){
			die "Can't identify the gene\n";
		}
		elsif(!defined $orthoGroup){
			print "There is no orthology group for $gene, I'll skip it\n";
		}
		else{
			push (@{$orthoList{$orthoGroup}},$gene);	
		}
		
	}
}

if (keys %orthoList == 0){
	die "The ortho list file (-g) couldn't be loaded.  Exiting\n";
}

if ($opts{'d'}){
	`rm $outDir/* -rf`;
}



foreach my $group (keys %orthoList){
	
	if ($opts{'m'}){
		my $tmpPepFH = File::Temp->new(DIR=>"./",UNLINK=>1);
		my $tmpPepFile= $tmpPepFH->filename;
		my $tmpNucFH = File::Temp->new(DIR=>"./",UNLINK=>1);
		my $tmpNucFile= $tmpNucFH->filename;
		
		
		my $foundFlag = 0;
		foreach my $gene (@{$orthoList{$group}}){
			#if (!$pepHash->{$gene} || !$nucHash->{$gene}){
			if (!$seqHash->{$gene}){
				print STDERR "Coulldn't find $gene in the fasta file\n";
				next;
			}
			$foundFlag =1;
			print $tmpPepFH ">$gene\n$seqHash->{$gene}->{'seq'}\n";
			#print $tmpNucFH ">$gene\n$nucHash->{$gene}->{'seq'}\n";
		}
		if ($foundFlag == 0){
			print STDERR "The $group group didn't have any genes in the fasta file\n";
			next;
		}
		print STDERR "runningalign\n";
		&runAlign($group."_align",$tmpPepFile)
	}
	else{
		my $foundFlag = 0;
		my @genes = @{$orthoList{$group}};
		$groupListing .= "group=$group\n".join(":",@genes)."\n";
		#foreach my $g (@genes){
		#	if ($g =~ "scaffold_200287.1"){
		#		print "included:".join(":",@genes)."\n";
		#		last;
		#	}
		#}
		
		for (my $i = 0; $i<(@genes-1); $i++){
			#if (!$pepHash->{$genes[$i]} || !$nucHash->{$genes[$i]}){
			if (!$seqHash->{$genes[$i]}){
					print STDERR "Couldn't find $genes[$i] in the fasta file\n";
					next;
				}
			for (my $j = ($i+1);$j < @genes;$j++){
				#if (!$pepHash->{$genes[$j]} || !$nucHash->{$genes[$j]}){
				if (!$seqHash->{$genes[$j]}){
					print STDERR "Coulldn't find $genes[$j] in the fasta file\n";
					next;
				}
				my $tmpPepFH = File::Temp->new(DIR=>"./",UNLINK=>1);
				my $tmpPepFile= $tmpPepFH->filename;
				my $tmpNucFH = File::Temp->new(DIR=>"./",UNLINK=>1);
				my $tmpNucFile= $tmpNucFH->filename;
			
				#print STDERR ">$genes[$i]\nseq=$pepHash->{$genes[$i]}->{'seq'}\n";
				#exit;
		
				print $tmpPepFH ">$genes[$i]\n$seqHash->{$genes[$i]}->{'seq'}\n";
				#print $tmpNucFH ">$genes[$i]\n$nucHash->{$genes[$i]}->{'seq'}\n";
				print $tmpPepFH ">$genes[$j]\n$seqHash->{$genes[$j]}->{'seq'}\n";
				#print $tmpNucFH ">$genes[$j]\n$nucHash->{$genes[$i]}->{'seq'}\n";
				
				my $pepOut = $genes[$i]."--".$genes[$j]."_align";
				#my $nucOut = $genes[$i]."--".$genes[$j]."_nucAlign";
				#&runAlign($pepOut,$nucOut,$tmpPepFile,$tmpNucFile)
				print "running $pepOut,$tmpPepFile\n";
				&runAlign($pepOut,$tmpPepFile)
			}
		}
		
		
=begin
			if (!$pepHash->{$gene} || !$nucHash->{$gene}){
				print STDERR "Coulldn't find $gene in the fasta file\n";
				next;
			}
			$foundFlag =1;
			print $tmpPepFH ">$gene\n$pepHash->{$gene}->{'seq'}\n";
			print $tmpNucFH ">$gene\n$nucHash->{$gene}->{'seq'}\n";
		}
		if ($foundFlag == 0){
			print STDERR "The $group group didn't have any genes in the fasta file\n";
			next;
		}
=cut
	}
	#my $pepAlignName = $group."_pepAlign";
	#my $nucAlignName = $group."_nucAlign";
	#my $cmd = "linsi $tmpPepFile > $pepAlignName";
	#`$cmd`;
	#$cmd = "tranalign -psequence $pepAlignName -nsequence $tmpNucFile -outseq $nucAlignName";
	#`$cmd`;
}

print "\nGroupListing:\n$groupListing";

sub runAlign {
	my $pAlignName = shift;
	#my $nAlignName = shift;
	my $tempPep = shift;
	#my $tempNuc = shift;
	my $cmd = "linsi $tempPep > $outDir/$pAlignName.fa";
	`$cmd`;
	#print "Done with $cmd\n";
	#$cmd = "tranalign -bsequence $outDir/$pAlignName -asequence $tempNuc -outseq $outDir/$nAlignName";
	#print STDERR "running $cmd\n";
	#`$cmd`;
}






sub loadFasta{
	my $fName = shift;
	open (FH,$fName) or die "Can't open $fName\n";
	my %returnHash;
	my @order;
	my $sequence = "";
	my $header = "";
	my $desc = "";
	while (my $line = <FH>){
		next if ($line =~ /^[\n\r]+$/);
		chomp $line;
		if ($line =~ />/){
			my @headerPieces = split(/\s/,$line,2);
			$headerPieces[0] =~ s/^>//;
			if ($sequence ne "" && $header ne "") {
				$returnHash{$header}->{'seq'} = $sequence;
				$returnHash{$header}->{'desc'} = $desc;
			}
			$header = $headerPieces[0];
			$desc = $headerPieces[1] || "";
			push (@order,$header);
			$sequence = "";
		}
		else {
			$sequence .= $line;
		}

		if (eof FH) {
			$returnHash{$header}->{'seq'} = $sequence;
			$returnHash{$header}->{'desc'} = $desc;
		}
	}
	
	return (\%returnHash,\@order);
	
}

sub varcheck {
	my $errors = "";
	if (!$opts{'s'}){
		$errors .= "-s flag not provided\n";
	}
	elsif(!(-e $opts{'s'})) {
		$errors .= "Can't open $opts{'s'}\n";
	}
	#if (!$opts{'n'}){
	#	$errors .= "-n flag not provided\n";
	#}
	#elsif(!(-e $opts{'n'})) {
	#	$errors .= "Can't open $opts{'n'}\n";
	#}
	if (!$opts{'o'}){
		$errors .= "-o flag not provided\n";
	}
	elsif(!(-d $opts{'o'})) {
		$errors .= "$opts{'o'} is not a directory\n";
	}
	
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName <-s fasta file> <-o dir> [-g file, -m,-d] \n";
print <<PRINTTHIS;

Run alignment program on orthologs.  Loads a peptide fasta file and an ortholog list and runs
an alignment program on each ortholog set.  If no ortholog file is given, it assumes
all sequences in the fasta are orthologs.  A separate file for each pairwise comparison will
be output unless the -m flag is thrown.

Mandatory:
-o directory destination of output
-s sequence fasta file


Optional:
-g ortholog Sets to Group on.  Two column text file with seq header and ortho name, tab separated.
-m runs multiple alignment (default is pairwise alignments)
-d deletes the contents of the output directory before running
	
PRINTTHIS
	exit;
}