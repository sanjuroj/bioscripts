#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('a:b:',\%opts); 

&varcheck;

open (AF,$opts{'a'}) or die "Can't open $opts{'a'}\n";
open (BF,$opts{'b'}) or die "Can't open $opts{'b'}\n";


my ($fileAgenes,$fileAorder,$fileAerrors) = &loadGff(\*AF);
my ($fileBgenes,$fileBorder,$fileBerrors) = &loadGff(\*BF);

my @stats = qw (start end len cdsCount cdsLen);

my ($sameCount,$diffCount) = (0,0);
my (%notInA,%notInB);

print "gene\tA_start\tB_start\tA_end\tB_end\tA_len\tB_len\tA_cdsCount\tB_cdsCount\tA_cdsLen\tB_cdsLen\n";
foreach my $ag (@{$fileAorder}){
	if (!$fileBgenes->{$ag}){
		$notInB{$ag} = 1;
		next;
	}
	my $aStats = $fileAgenes->{$ag};
	my $bStats = $fileBgenes->{$ag};
	
	my $diffFlag = 0;
	foreach my $stat (@stats){
		if (($aStats->{$stat} ne $bStats->{$stat})) {
			$diffFlag =1;
		}
	}
	if ($diffFlag == 1){
		$diffCount++;
		print "$ag";
		foreach my $stat (@stats){
			print "\t$aStats->{$stat}\t$bStats->{$stat}";
		}
		print "\n";
		
	}
	else{
		$sameCount++;
	}
}

foreach my $bg (@{$fileBorder}){
	if (!$fileAgenes->{$bg}){
		$notInA{$bg}=1;
	}
}

print "\n$sameCount Genes were the same\n" if $sameCount > 0;
print "$diffCount Genes were different\n" if $diffCount > 0;
if (keys %notInB > 0){
	print "These genes were in file A but not in file B:\n";
	print join("\n",keys %notInB)."\n";
}
if (keys %notInA > 0){
	print "\nThese genes were in file B but not in file A:\n";
	print join("\n",keys %notInA)."\n";
}




sub loadGff{
	my $fh = shift;
	my (@order,%geneList,$gene,$errors);
	while (my $line = <$fh>){
		next if $line =~ /^[\s]*\n$/;
		next if $line =~ /^#/;
		chomp $line;
		my ($chr,$source,$type,$start,$end,$score,$strand,$phase,$note) = (split("\t",$line));
		
		
		if ($type eq "mRNA"){
			$note =~ /ID=([^;]+)/;
			$gene = $1;
			my $length = $end-$start+1;
			my %tHash = ('start'=>$start, 'end'=>$end, 'len'=>$length); 
			$geneList{$gene} = \%tHash;
			push (@order,$gene);
		}
		if ($type eq "CDS"){
			$note =~ /Parent=([^;]+)/i;
			$gene = $1;
			if ($gene=~/,/){
				my @genes = split(",",$gene);
				foreach my $g (@genes){
					$gene = $g if $g =~ /AT\dG\d+\.\d$/;
				}
				
			}
			if ($gene !~ /AT\dG\d+\.\d$/){
				$errors .= "Couldn't load $gene\n";
				next;
			}
			$geneList{$gene}->{'cdsCount'}++;
			$geneList{$gene}->{'cdsLen'} += ($end-$start+1);
		}
	}
	
	return (\%geneList,\@order,$errors);
}

sub varcheck {
	my $errors = "";
	if (!$opts{'a'}){
		$errors .= "-a flag not provided\n";
	}
	elsif(!(-e $opts{'a'})) {
		$errors .= "Can't open $opts{'a'}\n";
	}
	if (!$opts{'b'}){
		$errors .= "-b flag not provided\n";
	}
	elsif(!(-e $opts{'b'})) {
		$errors .= "Can't open $opts{'b'}\n";
	}
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName <-a gff file> <-b gff file>\n";
print <<PRINTTHIS;

Compares genes of two versions of TAIR.

-a One version of TAIR genes,  .gff format
-b The other version of TAIR genes, .gff format
	
PRINTTHIS
	exit;
}