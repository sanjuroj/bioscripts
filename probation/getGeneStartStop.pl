#!/usr/bin/perl

use strict;
use warnings;

sub usage()
{
   print STDERR q
   ( Usage: checkSnapFile.pl <snapFile> <acidFile> <nucFile>
   
	   Checks the SNAP gene prediction file to make sure it corresponds to 
	   the amino acid and nucleotide files provided.  Checks the first and
	   last codons of each gene.
	  
	   
   );
   exit;
}

if ( ( @ARGV == 0 ) || $ARGV[0] eq "-h" )   #no arguments or help option
{
      &usage();
}



my $snapFile = $ARGV[0];
my $acidFile = $ARGV[1];
my $nucFile = $ARGV[2];
my @codons;
my $codonCount = 0;
open (SFILE, $snapFile);
my @snapLines=<SFILE>;
for ( my $i=0; $i<@snapLines; $i++) {
	my @line = split(/\s+/,$snapLines[$i]);
	my $codonInfo=""; # codon start, direction,gene name,codon,amino
	my $scaffName;
	if($line[2] eq "gene"){
		#print "@line\n";
		if ($line[6] eq "+"){
			$codonInfo = $line[3];
			$codonInfo .= "\t+";
			$line[0] =~ /(\d+)/;
			$codonInfo .= "\t$1";
		}
		else {
			$codonInfo = $line[4];
			$codonInfo .= "\t-";
			$line[0] =~ /(\d+)/;
			$codonInfo .= "\t$1";
			
		}
		#for (my $j=0; $j<3; $j++){
		#	print "pos",$j,"=",$codonPos[$j];
		#}
		#print "\n";
		my @gName = split (/[=;]/,$line[8]);
		$codonInfo .= "\t$gName[1]";
		$codons[$codonCount++] = $codonInfo;
			
	}
}

close SFILE;

my $currentScaff=0;
my $scaffold="";

for (my $i=0; $i<10; $i++){
	my @codonInfo = split (/\t/,$codons[$i]);
	if ($currentScaff != $codonInfo[2]){
		print "loading scaff $codonInfo[2]\n";
		&loadScaff($codonInfo[2]);
		$currentScaff = $codonInfo[2];
	}
	my $codonLetters =  "";
	if($codonInfo[1] eq "+"){
		$codonLetters = substr($scaffold,$codonInfo[0],3);
	}
	else {
		$codonLetters = reverse(substr($scaffold,$codonInfo[0]-2,3));
	}
	print "codonLetters=",$codonLetters,"\n";
}
	


my $checkLen = @codons;
print "codons len=",$checkLen,", cod count=$codonCount\n";
for (my $j=0; $j<3; $j++){
	my @printIt = split (/\t/,$codons[$j]);
	print "start=$printIt[0], dir=$printIt[1], gene name=$printIt[3]";
	print ", scaff=$printIt[2]\n";
}
print "\n";





sub loadScaff {
	my ($target) = shift (@_);
	#print "gothere\n";
	my $scaffPath = "C:\\Documents and Settings\\Sanjuro\\My Documents\\My Stuff\\hcgs\\Scaffolds\\"; #sj home scaffpath
	open (SCAFF, $scaffPath.$nucFile) or die ;
	my $found = 0;
	while ($found != 2 and my $scaffLine=<SCAFF>){
		#print "found=$found\n";
		if(substr($scaffLine,0,1) eq ">"){
			#print "found=$found\n";
			if($found==0){
				my @headerInfo = split(/\s+/,$scaffLine);
				$headerInfo[0] =~ /(\d+)/;
				#print "tempscaff=$1, targetscaff=$target\n";
				if( $1 == $target){
					$found++;
				}
			}
			else{
				$found++;
			}
				
		}
		else{
			if ($found==1){
				chomp ($scaffLine);
				$scaffold .= $scaffLine;
			}
		}
		
	} 
	
	
	
}

