#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('ha:f:b:g:t:o:',\%opts); 

&varcheck;

my %cutThese;
my $frontTrim = $opts{'f'} || 0;
my $backTrim = $opts{'b'} || 0;
my $outFile = $opts{'o'} || "-";


#load the fasta file into two data structures. $rawAligns has taxa as ky, $posArray has position as key.
#Easier to search through $posArray for gaps, easier to remove positions from $rawAligns.
my ($taxOrder,$posArray,%rawAligns);
open (IN,$opts{'a'}) or die "Can't open $opts{'a'}\n";
my ($taxName,$taxString);
while (my $line = <IN>){
	next if $line=~/^\n+$/;
	next if $line=~/^#/;
	chomp $line;
	#print "$line\n";
	if ($line=~/>(.*)/){
		if (defined $taxName){
			($posArray,$taxOrder) = &addTaxa($taxName,$taxString,$posArray,$taxOrder);
		}
		$taxName = $1;
		$taxString = "";
	}
	else{
		$taxString .= $line;
		$rawAligns{$taxName} .= $line;
	}
}
($posArray,$taxOrder) = &addTaxa($taxName,$taxString,$posArray,$taxOrder);

close IN;

#identify gaps that are eligible for cutting by looping through each position and checking for gap chars
my $gapStart = -1;
my $gapEnd = -1;
my $taxCount = @{$taxOrder};
my $minGapCount = $opts{'t'} || 1;
if ($minGapCount > $taxCount){
	$minGapCount = $taxCount;
}
my $minGapLen = $opts{'g'} || 1;
my %cutGaps;
if ($opts{'g'}){
	foreach (my $i=$frontTrim; $i<@{$posArray};$i++){
		
		my $posString = $posArray->[$i];
		my $gapCount = $posString =~ tr/-/-/;
		#print "posstring=$posString\n";
		#print "gc=$gapCount,gt=$minGapCount,gl=".($gapEnd-$gapStart+1).":";
		
		if ($gapCount >= $minGapCount){
			#print "posString passed gap thresh=$posString\n";
			if ($gapStart < 0){
				$gapStart = $i;
				$gapEnd = $i;
			}
			else{
				$gapEnd = $i
			}
			if ($i==@{$posArray}-1 && $gapEnd-$gapStart+1 >= $minGapLen && $gapStart >-1){
				#print "pushing last, $gapStart,$gapEnd\n";
				foreach (my $a = $gapStart; $a<=$gapEnd;$a++){
					$cutThese{$a} = 1;
					$cutGaps{$a} = 1;
				}
			}
		}
		else{
			
			if ($gapEnd-$gapStart+1 >= $minGapLen && $gapStart >-1){
				#print "no thresh but good gap, $gapStart,$gapEnd\n";
				foreach (my $a = $gapStart; $a<=$gapEnd;$a++){
					$cutThese{$a} = 1;
					$cutGaps{$a} = 1;
				}
			}
			$gapStart = -1;
			$gapEnd = -1;
		}
	}	
	
}
#print "\n\n";
#my @cg = keys %cutGaps;
#@cg = sort {$a<=>$b} @cg;
#foreach (@cg){
#	print "$_:"
#}
#print "\n\n";


for (my $i=0; $i<$frontTrim;$i++){
	$cutThese{$i} = 1;
}
my $alignLen = length($rawAligns{$taxOrder->[0]});
for (my $i=($alignLen-$backTrim); $i<$alignLen;$i++){
	$cutThese{$i} = 1;
}


print STDERR "cutlist=".join(":",sort {$a<=>$b}(keys %cutThese))."\n";
my %outSeqs;
for (my $i=0;$i<$alignLen;$i++){
	if (!$cutThese{$i}){
		foreach my $t (@{$taxOrder}){
			$outSeqs{$t} .= substr($rawAligns{$t},$i,1);
		}
	}
	
}

if ($alignLen==(keys %cutThese)){
	print STDERR "Methinks you've trimmed too much.  There's no sequence left!\n";
}
else {
	print STDERR "There are ".($alignLen-(keys %cutThese))." residues remaining after trimming\n";
	open (OF,">$outFile") or die "Can't open $outFile\n";	
	foreach my $t (@{$taxOrder}){
		if(defined $outSeqs{$t}){
			print OF ">$t\n$outSeqs{$t}\n";
		}
	}
}


sub addTaxa {
	my ($tName,$tString,$pArray,$tOrder) = @_;
	my $alnLength = length($tString);
	my @spl = split("",$tString);
	for (my $i=0; $i<$alnLength;$i++){
		$pArray->[$i] .= $spl[$i];
	}
	push (@{$tOrder},$tName);
	return ($pArray,$tOrder)
}

sub varcheck {
	&usage if ($opts{'h'});
	my $errors = "";
	if (!$opts{'a'}){
		$errors .= "-a flag not provided\n";
	}
	elsif(!(-e $opts{'a'})) {
		$errors .= "Can't open $opts{'a'}\n";
	}
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName <-f file> [-c, -g, -t, -o]\n";
print <<PRINTTHIS;

--Trims residues from the beginning and end of the alignment.
--Excises gaps

-a fasta formatted alignment file

-o filename for output
-f number of positions to chop off the front of the alignment
-b number of positions to chop off the back of the alignment
	
-g minimum gap length for removal
-t minimum number of gaps at each position that would prompt retention.  For instance,
    -g 5 -t 2 would cut gaps of length five or greater where the gap was present
	in at least two taxa.
	
PRINTTHIS
	exit;
}