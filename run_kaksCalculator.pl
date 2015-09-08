#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use File::Temp;

my %opts;
getopts('i:o:d:',\%opts); 

&varcheck;

my $kaksCalcPath = '$HOME/programs/software/KaKs_Calculator1.2/src/KaKs_Calculator';
my $geneDelimiter = "--";  #delimiter for .axt file pairwise alignemnts

my $outFile = $opts{'o'} || "-";
my $errors = "\n";
if ($opts{'d'}){
	my (@wholeOutput,%scrollOutput);
	my $tempOut = File::Temp->new(UNLINK=>1);
	my @files = <$opts{'d'}*>;
	@files = grep(/fna.axt$/,@files);
	
	my $counter = 1;
	my $header;
	foreach my $file (@files){
		print STDERR "\nWorking on file ".$counter++." of ".@files." ($file)\n";
		
		#first do the whole gene
		execKaKsCalc($file,$tempOut);
		open (TO,$tempOut) or die "Can't open $tempOut\n";
		my @result = <TO>;
		close TO;
		if (!$result[1] || $result[1] eq ""){
			$errors.="$file is blank\n";
		}
		else{
			push (@wholeOutput,$result[1]);
			$header = $result[0];
		}
		
		print STDERR "Done with $file\n+++++++++++++++++++\n";
		#now do the scroll
		#&calcScroll($file);
	
	}
	
	open (OUT,">$outFile") or die "Can't open $outFile\n";
	print OUT $header;
	print OUT join("",@wholeOutput)."\n";
	print STDERR $errors;
	
}
else {
	execKaKsCalc($opts{'i'},$outFile);
	#&calcScroll($opts{'i'});
}

sub calcScroll {
	my $in = shift;
	open (AL,$in) or die "Can't open $in\n";
	my @alignLines = <AL>; #line are gene names, gene1 alignment, gene2 alignment
	chomp @alignLines;
	my ($gene1,$gene2) = split($geneDelimiter,$alignLines[0]);
	my @gene1Map = makeAlignGeneMap($alignLines[1]);
	my @gene2Map = makeAlignGeneMap($alignLines[2]);
	my $startPos = 0;
	my $endPos = @gene2Map;
	
	if ($opts{'w'} > $endPos){
		print STDERR "The window size is larger than the alignment. Exiting\n";
		exit;
	}
	
	my $posIndex = 0;
	
	while ($posIndex+$opts{'w'}<=$endPos){
		print "w=$opts{'w'}, endpos=$endPos, pind=$posIndex\n";
		my $gene1Frag = substr($alignLines[1],$posIndex,$opts{'w'});
		my $gene2Frag = substr($alignLines[2],$posIndex,$opts{'w'});
		print "g1=$gene1Frag, g2=$gene2Frag\n";
		if (!($gene1Frag =~ /[-_\.]/) && !($gene2Frag =~ /[-_\.]/)){
			my $fragIn = File::Temp->new(UNLINK=>0,DIR=>"./");
			my $fragOut = File::Temp->new(UNLINK=>0,DIR=>"./");
			open (FI,">$fragIn") or die "Can't open $fragIn\n";
			print FI "temp\n$gene1Frag\n$gene2Frag";
			close FI;
			print "fragin=$fragIn\n";
			open (FI,$fragIn) or die "can't open $fragIn\n";
			my @test = <FI>;
			if (@test==0){
				print STDERR "FI is empty\n";
			}
			else{
				print STDERR "FI:\n".join("\n",@test)."\n";
			}
			
			
			execKaKsCalc($fragIn,$fragOut);
			print STDERR "\n";
			
			open (FO,$fragOut) or die "Can't open $fragOut\n";
			my @fragOutLines = <FO>;
			close FO;
			if (@fragOutLines == 0){
				print STDOUT "fragout lines = 0";
			}
			else{
				print "out=$fragOutLines[1]\n";
			}
		}
		
		$posIndex += $opts{'s'};
	}
	
	
}



# maps alignment positions to ungapped gene positions
sub makeAlignGeneMap {
	print "****************************************\n";
	my @align = split("",shift);
	my $posCount = 0;
	my @map;
	
	for (my $i=0;$i<@align;$i++){
		$map[$i] = ($align[$i] !~ /[acgtuACGTU]/) ? "Z" : $posCount++; 
	}
	#print "al=".join("",@align)."\n";
	#print join("\n",@map)."\n";
	return @map;
}


sub execKaKsCalc {
	my $in = shift;
	my $out = shift;
	open (TE,$in) or die "Cn't\n";
	my @t = <TE>;
	#print join("\n",@t)."\n";
	close TE;
	my $cmd = "$kaksCalcPath -i $in -o $out";
	print "cmd=$cmd\n";
	system $cmd;
	
}



sub varcheck {
	my $errors = "";
	if (!$opts{'i'} && !$opts{'d'}){
		$errors .= "-i or -d flag must be provided\n";
	}
	elsif(!$opts{'d'} && !(-e $opts{'i'})) {
		$errors .= "Can't open $opts{'i'}\n";
	}
	
	
=begin	
	if (!$opts{'s'} || !$opts{'w'}){
		$errors .= "-w and -s flag must both be provided";
		
	}
	else{
		if($opts{'s'}%3 != 0){
			$errors .= "The scroll length (-s) must be a multiple of three\n";
		}
		if($opts{'w'}%3 != 0){
			$errors .= "The window size (-w) must be a multiple of three\n";
		}
		
		if ($opts{'s'} > $opts{'w'}){
			$errors .= "The scroll size is larger than the window\n";
		}
	}
=cut
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName <-i axt file> <-o outputFile> [-d]\n";
	#-s scroll distance (e.g. 3 for 3nt).  Must be a multiple of 3.
	#-w window size for the scroll (e.g. 21 for 21nt).  Must be a multiple of 3.
print <<PRINTTHIS;

Caluclates KaKs ratio of aligned genes

-i is the alignment file in .atx format
-o is the name of the output file
-d will run KaKs on the current directory and will put all the results in the file specified by the -o flag

	
PRINTTHIS
	exit;
}