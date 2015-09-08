#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:d:r:n:',\%opts);

checkVars();

my $maxHitCount = $opts{'n'} || 1;

open (IN,"head -n 200 $opts{'f'} | sort -k1,1 -k12,12nr |") or die "Can't open $opts{'f'}\n";


my %geneHash;
while (my $line = <IN>) {
	
	chomp $line;
	my @lineSplit = split (/\t/,$line);
	my $query = $lineSplit[0]; #query gene
	my $hit = $lineSplit[1]; #hit gene
	my $bitScore = $lineSplit[11]; #hit gene
	#print "q=$q, h=$h\n";
	if ($query ne $hit){
		if(!($geneHash{$query}->{'lines'})) {
			$geneHash{$query}->{'best'} = $lineSplit[1];
			push (@{$geneHash{$query}->{'lines'}},\@lineSplit);
			$geneHash{$query}->{'lastBitScore'} = $lineSplit[11];
			$geneHash{$query}->{'count'} = 1;
			#print "first=$lineSplit[0]\n";
		}
		else {
			if ($geneHash{$query}->{'count'} < $maxHitCount){
				push (@{$geneHash{$query}->{'lines'}},\@lineSplit);
				if ($geneHash{$query}->{'lastBitScore'} != $lineSplit[11]){
					$geneHash{$query}->{'count'} += 1;		
				}
				$geneHash{$query}->{'lastBitScore'} = $lineSplit[11];
			}
			
		}
	
	}
}

#print "starthashdump\n";
#print "\n\n";
#foreach my $k (keys %geneHash){
#	print "$k\t";
#	my @hits = @{$geneHash{$k}->{'lines'}};
#	foreach (@hits){
#		print join("\t",@{$_})."\n";
#	}
#}
#


if ($opts{'d'}){
	open (DI,$opts{'d'});
	my %geneHash;
	while (my $line = <DI>){
		chomp $line;
		my ($gene,$diff) = split(/\t/,$line);
		$geneHash{$gene}->{'group'} = $diff;
	}
	close DI;
}






my (%printedHits,%recipGenes);
print "\nReciprocal Best Blast Hits\n";
foreach my $thisGene (keys %geneHash){
	my $otherGene  = $geneHash{$thisGene}->{'lines'}->[0]->[1];
	my $thisGroup = $geneHash{$thisGene}->{'group'};
	my $otherGroup = $geneHash{$otherGene}->{'group'};
	if ($thisGroup ne $otherGroup && !$printedHits{$thisGene} && !$printedHits{$otherGene}) {
		print "$thisGene\t$otherGene\n";
		$printedHits{$thisGene}=1;
		$printedHits{$otherGene}=1;
		$recipGenes{$thisGene}=1;
		$recipGenes{$otherGene}=1;
	}
}

print "\n\nGenes whose best hit was in the reciprocal best list\n"; 

foreach my $gene (keys %geneHash){
	if (!$printedHits{$gene}){
		my $bestHit = $geneHash{$gene}->{'best'};
		if ($recipGenes{$bestHit}){
			print "$gene\t$bestHit\n";
			$printedHits{$gene} = 1;
		}
	}

}

if ($opts{'g'}){
	
	print "\n\nBest hits against any gene in group $opts{'g'}\n"; 
	
	foreach my $gene (keys %geneHash){
		if (!$printedHits{$gene}){
			my $bestHit = $geneHash{$gene}->{'best'};
			my $otherGroup = $geneHash{$bestHit}->{'group'};
			if ($otherGroup eq $opts{'g'}){
				print "$gene\t$bestHit\n";
				$printedHits{$gene} = 1;
				$printedHits{$bestHit} = 1;
			}
		}
	
	}
	
	print "\n\nGenes in group $opts{'g'} absent in results of prior analyses\n"; 

	my $counter = 0;	
	foreach my $gene (keys %geneHash){
		if (!$printedHits{$gene}){
			my $group = $geneHash{$gene}->{'group'};
			if ($group eq $opts{'g'}){
				print "$gene\t".$geneHash{$gene}->{'best'}."\n";
				$printedHits{$gene} = 1;
				$counter++;
			}
		}
	
	}
	print "none\n\n" if $counter == 0;
	
	
	
}

sub checkVars {
	if ( !$opts{'f'} )
	{
		  print "optsf=$opts{'f'}\n";
		  &usage();
	}
}

sub usage() {
   print STDERR <<PRINTTHIS;

Usage: recipBestBlast.pl -f <blast result> [-g & -d,-r]
   
Prints Best Blast Hits

-n Number of best hits to print.  Default is 1.
 
-d should be a file with the list of genes in one column and a
differentiator in the second (tab delimited) column.  For instance the
numbers 1 and 2, or the text x and y.
 
-g is a flag that tell the script "I also want the best hit against any gene
in this group of genes".  A group name is one of the differentiator values
in the differentiator files.  For instance, if I want to blast genome1
against genome2 and am interested in anything that hits against genome1,
I would use -r genome1.

-r List of reciprocal best blast hits will be printed separately

	   
PRINTTHIS
   exit;
}



