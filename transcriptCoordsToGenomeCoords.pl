#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('g:l:',\%opts); 

&varcheck;

my (%loci,%gff);

open (LH,$opts{'l'}) or die "Can't open $opts{'l'}\n";
while (my $l = <LH>){
	chomp $l;
	my ($id,$start,$stop) = split(/\t/,$l);
	$loci{$id}->{'start'}=$start;
	$loci{$id}->{'stop'}=$stop;
	
}

open (GH,$opts{'g'}) or die "Can't open $opts{'g'}\n";

my %strandInfo;
while (my $g = <GH>){
	next if $g =~ /^\s+$/;
	chomp $g;
	my ($gStart,$gStop,$strand,$name) = (split(/\t/,$g))[3,4,6,8];
	$strandInfo{$name} = $strand;
	my @positions;
	if ($strand eq "+"){
		for (my $i = $gStart; $i <= $gStop; $i++){
			push (@positions,$i);
		}
	}
	else {
		for (my $i = $gStop; $i >= $gStart; $i--){
			push (@positions,$i);
		}
	}
	push (@{$gff{$name}},\@positions);
}


foreach my $locus (keys %loci){
	print "$locus\t";
	my $strand = $strandInfo{$locus};
	my @gPositions = @{$gff{$locus}};
	if ($strand eq "-"){
		@gPositions = reverse(@gPositions);
	}
	my $lStart=$loci{$locus}->{'start'};
	my $lStop=$loci{$locus}->{'stop'};
	my $gPosCounter = 1;
	
	my @outPos;
	my $seq;
	
	for (my $i=0; $i<@gPositions; $i++){
		my ($rangeStart,$rangeStop) = (0,0);
		my @exonPositions = @{$gPositions[$i]};
		foreach my $ePos (@exonPositions){
			#print "gposcount=$gPosCounter, lstart=$lStart,epos=$ePos\n";
			if($gPosCounter >= $lStart && $gPosCounter <= $lStop){
				#print "gothere\n";
				if ($rangeStart == 0){
					$rangeStart = $ePos;
				}
				else {
					$rangeStop = $ePos;
				}
			}
			$gPosCounter++;
			last if $gPosCounter > $lStop;
		}
		if ($rangeStart > 0){
			if ($strand eq "+"){
				push (@outPos,$rangeStart."-".$rangeStop);
			}
			else {
				push (@outPos,$rangeStop."-".$rangeStart);
			}
		}
		last if $gPosCounter > $lStop;
		
		#last if $gPositionCounter == $locusPositions[@locusPositions-1];
	}
	if ($strand eq "-"){
		@outPos = reverse @outPos;
	}
	print join(":",@outPos);
	print "\n";
}


#=begin
print "\n\n";
foreach (keys %loci){
	print "locus=$_,start=".$loci{$_}->{'start'}.",stop=".$loci{$_}->{'stop'}."\n";
}

print "\n";

foreach my $g (keys %gff){
	print "$g:";
	my @exons = @{$gff{$g}};
	foreach my $exon (@exons){
		my @e = @{$exon};
		print $e[0]."-".$e[@e-1].",";
	}
	print "\n";
}
#=cut





sub varcheck {
	my $errors = "";
	if (!$opts{'l'}){
		$errors .= "-l flag not provided\n";
	}
	elsif(!(-e $opts{'l'})) {
		$errors .= "Can't open $opts{'l'}\n";
	}
	if (!$opts{'g'}){
		$errors .= "-g flag not provided\n";
	}
	elsif(!(-e $opts{'g'})) {
		$errors .= "Can't open $opts{'g'}\n";
	}
	
	if ($errors ne "") {
		print $errors;
		&usage;
	}
}

sub usage{
	print STDERR "\nusage: perl transcriptToGenomeCoords -g gffFile -l locus file\n";
	print STDERR "\nConverts a a single transcript start stop to genome coordinates\n";
	print STDERR "\ntranscript file should be tab delimited with id, start, stop\n";
	print STDERR "\n";
	print STDERR "\n\n";
	exit;
	
}