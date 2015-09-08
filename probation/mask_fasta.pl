#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:c:eis',\%opts);

my $fastaFile = $opts{'f'};
my $coordFile = $opts{'c'};
&varcheck;

my $inverseFlag = defined $opts{'i'} ? 1 : 0;
my $exciseFlag = defined $opts{'e'} ? 1 : 0;
my $strictFlag = defined $opts{'s'} ? 1 : 0;

open (COORD,$coordFile) or die "Can't open $coordFile\n";

my (%coordinates);
while (my $line = <COORD>) {
	chomp $line;
	my @lSplit = split (/\t/,$line);
	push (@{$coordinates{$lSplit[0]}},"$lSplit[1]\t$lSplit[2]");
}

close COORD;

open (FA,$fastaFile) or die "Can't open $fastaFile\n";


my $header = "";
my $sequence = "";
my $countThis=0;
while (my $line = <FA>) {
	chomp $line;
	if ($line =~ />(.*)\s*/ || eof (FA)) {
		
		my $newHeader = $1;
		if ($header eq "") {
			$header = $newHeader;
			next;
		}
		
		if (eof(FA)){
			$sequence .= $line;
		}
		
		if (!$coordinates{$header}){
			if ($inverseFlag == 0 || ($inverseFlag == 1 && $strictFlag == 0)){
				$sequence =~ s/\n//g;
				my $sLen = length($sequence);
				$sequence = "N"x$sLen;
				print ">$header\n$sequence\n";
			}
			$header = $newHeader;
			$sequence = "";
			next;
		}
		
		my @coords = sort coordSort @{$coordinates{$header}};
		my $seqLen = length($sequence);
		$coords[(@coords-1)] =~ /\t(.*)/;
		if ($1 > $seqLen) {
			print "Coordinate positions exceed sequence length for $header, exiting\n";
			exit;
		}
		
		
		if ($inverseFlag == 0){
			foreach (@coords){
				my ($start,$stop) = split(/\t/,$_);
				my $len = $stop - $start +1; 
				substr($sequence,$start-1,$len,"Z"x$len);
				#substr($sequence,$start-1,$len,"N"x$len);
				if ($stop > $seqLen){
					print STDERR "\nCoordinate greater than sequence length for $header\n";
					exit;				
				}
			}
			
			if ($exciseFlag == 1) {
				$sequence =~ s/Z//g;
			}
			else {
				$sequence =~ s/Z/N/g;
			}
			print ">$header\n$sequence\n";
			
			
			#print "len=".length($sequence);
		}
		else{
			my $maskStart = 0;
			#open (OUT,">zzout5");
			
			for (my $i = 0; $i < @coords; $i++){
				
				my ($start,$stop) = split(/\t/,$coords[$i]);
				my $len = $start - 2 -$maskStart + 1;
		
				if ($len <= 0) {
					if ($i == @coords-1) {
						$len = $seqLen-$stop;
						substr($sequence,$stop,$len,"Z"x$len);
						#substr($sequence,$stop,$len,"N"x$len);
						next;
					}
		
					$countThis++;
					#print "len to small, i=$i\n";
					$maskStart = $stop if ($stop > $maskStart);
					next;
				}
							
				substr($sequence,$maskStart,$len,"Z"x$len);
		
				if ($i == @coords-1) {
					#print STDERR "GOTHERE\n";
					$len = $seqLen-$stop;
					substr($sequence,$stop,$len,"Z"x$len);
					#substr($sequence,$stop,$len,"N"x$len);
				}
				
				$maskStart = $stop;
			}
			
			if ($exciseFlag == 1) {
				$sequence =~ s/Z//g;
			}
			else {
				$sequence =~ s/Z/N/g;
			}
			print ">$header\n$sequence\n";
			
		}
		$header=$newHeader;
		$sequence = "";
		
	}
	else {
		$sequence .= "$line";
	}
	
	
}


print STDERR "overlapcount=$countThis\n";


sub coordSort {
	my ($aStart,$aStop) = split (/\t/,$a);
	my ($bStart,$bStop) = split (/\t/,$b);
	return $aStart<=>$bStart;
}


sub varcheck {
	if (!(-e $fastaFile) || !(-e $coordFile)) {
		&usage;
	}
}

sub usage{
	print STDERR "\nusage: perl mask_fasta <-f fastaFile> <-c mask coordinates> [-i] [-e]\n";
	print STDERR "\nFasta file can be multifasta.\n";
	print STDERR "Coordinate file should by tab separated fasta id, start, stop\n";
	print STDERR "\n-i flag will mask the inverse of the given coordinates (i.e.\n";
	print STDERR "  masks everything except for the coordinates given)\n";
	print STDERR "-e will excise residues instead of masking\n";
	print STDERR "-s (along with -i) is for strict interpretation of the -i flag.\n";
	print STDERR "  This means fasta blocks with no coordinates mapping to them will not print\n";
	print STDERR "\n";
	exit;
	
}
