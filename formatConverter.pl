#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use Switch;

my %opts;
getopts('f:s:e:d:io:',\%opts); 

&varcheck;

my ($startHash,$endHash,$order);

my @files;
if ($opts{'d'}){
	@files = <$opts{'d'}*>;
}
else {
	push (@files,$opts{'f'});
}
my $outDir = $opts{'o'} || "./";
$outDir =~ s/\/$//;


foreach my $fileName (@files){
	my ($outName);
	
	open (FH,$fileName) or die "Can't open $fileName\n";
	
	my $skip = $opts{'i'} || 0;
	if ($skip > 0){
		while ($skip > 0){
			my $line = <FH>;
			$skip--;
		}
	}

	#load inputs
	switch($opts{'s'}){
		case 'fa' {($startHash,$order,$outName) = &loadFasta(\*FH,$fileName)};
		case 'fasta' {($startHash,$order,$outName) = &loadFasta(\*FH,$fileName)};
		case 'fna' {($startHash,$order,$outName) = &loadFasta(\*FH,$fileName)};
		case 'faa' {($startHash,$order,$outName) = &loadFasta(\*FH,$fileName)};
		case 'aln' {($startHash,$order,$outName) = &loadAln(\*FH,$fileName)};
	}
	
	$outName = $outDir."/".$outName;
	chomp $outName;
	
	
	#outputs
	switch($opts{'e'}){
		case 'axt' {&outputAxt($startHash,$order,$outName)};
		case 'lsFasta' {&outputLsFasta($startHash,$order,$outName)};
		case 'fa' {&outputFasta($startHash,$order,$outName,$opts{'e'})};
		case 'fasta' {&outputFasta($startHash,$order,$outName,$opts{'e'})};
		case 'fna' {&outputFasta($startHash,$order,$outName,$opts{'e'})};
		case 'faa' {&outputFasta($startHash,$order,$outName,$opts{'e'})};
		case 'phylip' {&outputPhylipRS($startHash,$order,$outName)};
	}
}
	



sub outputLsFasta{
	my $in = shift;
	my $ord = shift;
	my $oName = shift;
	
	my %csGrid;
	$csGrid{'A'}->[0]='A';
	$csGrid{'A'}->[1]='C';
	$csGrid{'A'}->[2]='G';
	$csGrid{'A'}->[3]='T';
	$csGrid{'C'}->[0]='C';
	$csGrid{'C'}->[1]='A';
	$csGrid{'C'}->[2]='T';
	$csGrid{'C'}->[3]='G';
	$csGrid{'G'}->[0]='G';
	$csGrid{'G'}->[1]='T';
	$csGrid{'G'}->[2]='A';
	$csGrid{'G'}->[3]='C';
	$csGrid{'T'}->[0]='T';
	$csGrid{'T'}->[1]='G';
	$csGrid{'T'}->[2]='C';
	$csGrid{'T'}->[3]='A';
	
	
	
	if ("$oName.fa" eq $opts{'f'}){
		$oName = "$oName\_conv"
	}
	
	open (OUT,">$oName.fa") or die "Can't open $oName.fa\n";
	#print the header
	foreach my $o (@{$order}){
		print OUT ">$o\n";
		my @seq = split("",$in->{$o}->{'seq'});
		my $firstLet = shift(@seq);
		if ($firstLet !~ /[a-zA-Z]/){
			die "$o\n$in->{$o}\nDoesn't start with a letter\n";
		}
		for(my $i=0;$i<@seq;$i++){
			my $secondLet = $csGrid{$firstLet}->[($seq[$i])];
			print OUT $secondLet;
			$firstLet = $secondLet;
		}
		print OUT "\n";
		
		
		#print $in->{$o}->{'seq'}."\n";
	}
	close OUT;
	
}


sub outputAxt{
	my $in = shift;
	my $ord = shift;
	my $oName = shift;
	#chomp $oName;
	$oName .= '.axt';
	open (OUT,">$oName") or die "Can't open $oName.axt\n";
	#print the header
	print OUT join("--",@{$ord})."\n";
	foreach my $o (@{$order}){
		print OUT $in->{$o}->{'seq'}."\n";
	}
	close OUT;
}


sub outputFasta{
	my $in = shift;
	my $ord = shift;
	my $oName = shift;
	my $suffix = shift;
	open (OUT,">$oName.$suffix") or die "Can't open $oName.$suffix\n";
	foreach my $o (@{$order}){
		print OUT ">$o\n".$in->{$o}->{'seq'}."\n";
	}
	close OUT;
	
}

sub outputPhylipRS {
	my $in = shift;
	my $ord = shift;
	my $oName = shift;
	open (OUT,">$oName.phy") or die "Can't open $oName.phy\n";
	my $seqLen = length($in->{$order->[0]}->{'seq'});
	print OUT "\t".@$ord."\t$seqLen\n";
	
	my $seqLenFlag=0;
	foreach my $o (@{$order}){
		$seqLenFlag = 1 if length($in->{$o}->{'seq'}) != $seqLen;
		print OUT "$o  ".$in->{$o}->{'seq'}."\n";
	}
	if ($seqLenFlag == 1){
		print STDERR "WARNING: the sequences are not of the same length.  This is\n";
		print STDERR "         inappropriate for a phylip file\n";
	}
	close OUT;
}


#Returns refs to a hash of the data and an array of the keys in order of appearance in the file
#The hash contains keys for the gene name (unique fasta id), which further point to
#'seq' and 'desc' for the sequence and the description (everything after the fasta id on the header line).
sub loadFasta{
	my $fh = shift;
	my $fName = shift;
	my %returnHash;
	my @order;
	my $sequence = "";
	my $header = "";
	my $desc = "";
	while (my $line = <$fh>){
		next if ($line =~ /^\n+$/);
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
	
	$fName = `basename $fName`;
	
	return (\%returnHash,\@order,$fName);
	
}

sub loadAln{
	my $fh = shift;
	my $fName = shift;
	my %returnHash;
	my @order;
	
	while (my $line = <$fh>){
		next if ($line =~ /^[\s\n]+$/);
		next if ($line =~ /^#/);
		chomp $line;
		my ($header,$aln) = split(/\s+/,$line);
		next if $header eq "";
		
		if (!$returnHash{$header}){
			push (@order,$header);
		}
		$returnHash{$header}->{'seq'} .= $aln;
	}
	
	return (\%returnHash,\@order,$fName);
	
}


sub varcheck {
	my $errors = "";
	
	if (!$opts{'f'} && !$opts{'d'}){
		$errors .= "-f or -d flag must be provided\n";
	}
	elsif(!$opts{'d'} && !(-e $opts{'f'})) {
		$errors .= "Can't open $opts{'f'}\n";
	}
	
	if (!$opts{'s'}){
		$errors .= "-s flag not provided\n";
	
	}
	
	if (!$opts{'e'}){
		$errors .= "-e flag not provided\n";
	}

	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = `basename $0`;
	chomp $scriptName;
	
	print "\nusage: perl $scriptName <-f file | -d dir> <-s format> <-e format> [-t number] [-o dir]\n";
print <<PRINTTHIS;

Converts files between different formats.  Comment lines starting with "#" are ignored.


-f file.  File to be converted.
-s starting format of the -f file.  Currently can handle:
   fasta (and the fa, fna, and faa variants)
   aln (clustalw output)
-e ending format desired.  Currently can handle:
   axt
   lsFasta:  letterspace fasta
   fasta (and the fa, fna, and faa variants)
   phylip (relaxed sequential format)

-d dir name. Causes all files in the specified directory to be converted
-o dir name.  Will route the output to the specified directory.  Without this flag output will
	be routed to directory from which the script is run
-i integer.  Specifies the number of lines to ignore at the top of the file 
	
PRINTTHIS
	exit;
}