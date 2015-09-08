#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('g:f:h',\%opts); 

&varcheck;

open (GFF,$opts{'g'}) or die "Can't open $opts{'g'}\n";
my $intronCount = 0;
my $prevID="";
while (my $gLine=<GFF>){
	next if $gLine =~/^#/;
	next if $gLine =~/^[\n\r]+$/;
	chomp $gLine;
	my @gLineSpl = split("\t",$gLine);
	my %lineData = ('seqid' => $gLineSpl[0],
					'source' => $gLineSpl[1],
					'type' => $gLineSpl[2],
					'start' => $gLineSpl[3],
					'stop' => $gLineSpl[4],
					'score' => $gLineSpl[5],
					'strand' => $gLineSpl[6],
					'phase' => $gLineSpl[7],
					'attribs' => $gLineSpl[8]);
	
	my %attribHash;
	if ($lineData{'attribs'} ne "."){
		my @attribSegs = split(";",$lineData{'attribs'});
		foreach my $as (@attribSegs){
			my ($id,$val) = split("=",$as);
			$attribHash{$id}=$val;
		}
	}
	$lineData{'attribs'}=\%attribHash;
	
	if ($lineData{'type'} !~ /CDS/i && $lineData{'type'} !~ /pseudogenic_CDS/i){
		next;
	}
	

	if ($prevID eq ""){
		if ($opts{'f'} =~ /attribs/){
			$opts{'f'} =~/attribs:(.*)/;
			$prevID = $lineData{'attribs'}->{$1};
		}
		else{
			$prevID = $opts{'f'};
		}
		next;
	}
	
	my $currID;
	if ($opts{'f'} =~ /attribs/){
		$opts{'f'} =~/attribs:(.*)/;
		$currID = $lineData{'attribs'}->{$1};
	}
	else{
		$currID = $lineData{$opts{'f'}};
	}
	
	if ($currID eq $prevID){
		$intronCount++
	}
	else {
		print "$prevID\t$intronCount\n";
		$intronCount = 0;
	}
	$prevID = $currID;
	
}



sub varcheck {
	&usage if ($opts{'h'});
	my $errors = "";
	if (!$opts{'g'}){
		$errors .= "You have not provided a value for the -g flag\n";
	}
	elsif(!(-e $opts{'g'})) {
		$errors .= "Can't open $opts{'g'}\n";
	}
	
	if (!$opts{'f'}){
		$errors .= "You have not provided a value for the -f flag\n";
	}
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName <-g file>\n";
print <<PRINTTHIS;

Will output a list of names and intron counts.  Uses CDS and/or pseudogenic_CDS lines only
-g gff file to process
-f field to group lines by.  Example: "seqid" or "attribs:ID"
     gff fields include seqid,source,type,start,stop,score,strand,phase, and attribs
	
PRINTTHIS
	exit;
}