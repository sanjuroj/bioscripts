#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('ha:o:f:b:g:t:i:',\%opts); 

&varcheck;

my ($cdsRawSeqs,$cdsOrder);

#read cds file if it is provided
if ($opts{'i'}){
	open (CH,$opts{'i'}) or die "Can't open $opts{'i'}\n";
	($cdsRawSeqs,$cdsOrder) = &loadFasta(\*CH);
	
	#get rid of extra nucs at the end (i.e. modulo 3 nucs)
	foreach my $cdsKey (keys %{$cdsRawSeqs}){
		my $seq = $cdsRawSeqs->{$cdsKey};
		my $mod = length($seq) % 3;
		if ($mod != 0){
			my $newSeq = substr($seq,0,(length($seq)-$mod));
			$cdsRawSeqs->{$cdsKey} = $newSeq;
		}
	}
	close CH;
}


my $frontTrim = $opts{'f'} || 0;
my $backTrim = $opts{'b'} || 0;

my @proteinFiles;
if (-d $opts{'a'}){
	$opts{'a'} .= "/" if ($opts{'a'}!~/\/$/);
	@proteinFiles = <$opts{'a'}*>;
}
else{
	push(@proteinFiles,$opts{'a'});
}


my $error = "";
foreach my $file (@proteinFiles){
	print "processing $file\n";
	
	my %cutThese;
	my $outFile;
	if ($opts{'o'} && -d $opts{'o'}){
		$outFile = $opts{'o'};
		$outFile .= $opts{'o'}=~/\/$/ ? "" : "/";
		$outFile .= `basename $file`;
		chomp $outFile;
		#$outFile .= "_trim";
	}
	elsif ($opts{'o'}){
		$outFile = $opts{'o'};
	}
	else {
		$outFile = $file."_trim";
	}
	
	#load the protein fasta file into two data structures. $rawAligns has taxa as key, $posArray has position as key.
	#Easier to search through $posArray for gaps, easier to remove positions from $rawAligns.
	my ($taxOrder,$posArray,%rawAligns);
	open (IN,$file) or die "Can't open $file\n";
	my ($taxName,$taxString);
	my $prior="";
	while (my $line = <IN>){
		next if $line=~/^[\n\r\s]+$/;
		next if $line=~/^#/;
		chomp $line;
		if ($line=~/>(.*)/){
			if (defined $taxName){
				#print "passing tn=$taxName,ts=$taxString\n";
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
	
	
	
	my $alignLen = @{$posArray};
	
	if ($opts{'f'} || $opts{'b'} || $opts{'g'}){
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
		
		foreach (my $i=$frontTrim; $i<@{$posArray};$i++){
			if ($opts{'g'}){
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
						}
					}
				}
				else{
					
					if ($gapEnd-$gapStart+1 >= $minGapLen && $gapStart >-1){
						#print "no thresh but good gap, $gapStart,$gapEnd\n";
						foreach (my $a = $gapStart; $a<=$gapEnd;$a++){
							$cutThese{$a} = 1;
						}
					}
					$gapStart = -1;
					$gapEnd = -1;
				}
			}
			#if one of the sequences has an X in it, cut the whole position
			#could be in the middle of the aligment because one sequence could be longer than other
			if ($posArray->[$i]=~/X/i){
				$cutThese{$i} = 1;
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
		$alignLen = length($rawAligns{$taxOrder->[0]});
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
			print STDERR "Methinks you've trimmed too much from $file.  There's no sequence left!\n";
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
	}
	
	if ($opts{'i'}){
		my %cdsOut;
		my $cdsOutName = $outFile."_forceNuc.fna";
		open (CO,">$cdsOutName") or die "Can't open $cdsOutName\n";
		
		foreach my $t (@{$taxOrder}){
			$t=~/(\S+)/;
			my $cdsKey = $1;
			my $cdsRaw = $cdsRawSeqs->{$cdsKey};
			my $aminoString = $rawAligns{$t};
			my $cdsAlign="";
			my $cdsMarker=0;
			if ($cdsRaw eq ""){
				print STDERR "Couln't find $t in the cds file\n";
				exit;
			}
			#print "cdsraw=$cdsRaw\n";
			for (my $i=0;$i<$alignLen;$i++){
				my $aminoChar = substr($rawAligns{$t},$i,1);
				#next if $aminoChar eq "X";
				if (!$cutThese{$i}){
					if ($aminoChar eq "-"){
						$cdsAlign .= "---";
					}
					else{
						#print "mark=$cdsMarker\n";
						$cdsAlign .= substr($cdsRaw,$cdsMarker,3);
					}
				}
				if ($aminoChar ne "-"){
					$cdsMarker += 3;
				}
			}
			$cdsOut{$t}=$cdsAlign;
		}
	
		foreach my $k (@{$taxOrder}) {
			print CO ">$k\n$cdsOut{$k}\n";
		}
		
	}

	
}


sub loadFasta {
	my $fh = shift;
	my %returnHash;
	my $header="";
	my $seq="";
	my @order;
	while (my $line = <$fh>){
		next if $line =~ /^#/;
		next if $line =~ /^[\n\r]+$/;
		chomp $line;
		if ($line=~/>(\S+)/){
			my $newHeader = $1;
			push (@order,$newHeader);
			if ($seq ne ""){
				$returnHash{$header} = $seq;
				$seq = "";
			}
			$header = $newHeader;
		}
		elsif (eof($fh)){
			$returnHash{$header}=$seq.$line;
		}
		else {
			$seq .= $line;
		}
	}
	return (\%returnHash,\@order);
}


sub addTaxa {
	my ($tName,$tString,$pArray,$tOrder) = @_;
	#print "tn=$tName, ts=$tString\n";
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
	elsif(!(-d $opts{'a'} || -f $opts{'a'})) {
		$errors .= "Can't open $opts{'a'}\n";
	}
	elsif (-d $opts{'a'} && !$opts{'o'}){
		$errors .= "The -o flag needs to be provided as a directory name"
	}
	elsif (-d $opts{'a'} && !(-d $opts{'o'})){
		$errors .= "The -o flag needs to be provided as a directory name"
	}

	if ($opts{'i'}){
		if (! (-e $opts{'i'})){
			$errors .= "The nucleotide file specified in -i doesn't exist\n";
		}
	}

	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName <-a algin file/dir [-o]> [-g,-t,-i]\n";
print <<PRINTTHIS;

--Trims residues from the beginning and end of the alignment.
--Excises gaps
--Optionally creates a trimmed CDS sequence based on the trimmed AA sequence

-a fasta formatted alignment file or a directory of aligned files
-o output directory, only needed if -a is a directory 

-i filename  Output will be a nucleotide fasta file corresponding to amino alignment.
     In this case -a input should be the protein fasta and -i input should be the nuc fasta

-f number of positions to chop off the front of the alignment
-b number of positions to chop off the back of the alignment	
-g minimum gap length for removal
-t minimum number of taxa with a gap at at each locus that would prompt excision.  For instance,
    -g 5 -t 2 would cut gaps of length five or greater if the gap is present
	in at least two taxa.
	
PRINTTHIS
	exit;
}
