#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('f:o:n:h',\%opts); 

&varcheck;

my $outfile = $opts{'o'} || "-";
my $num = $opts{'n'} || 1;

my @headers = `grep ">" $opts{'f'}`;
chomp @headers;

if ($num > @headers){
	print STDERR "You've selected more sequences than are in the file.  Exiting.\n";
	exit;
}
if ($num == @headers){
	print STDERR "You've selected the same number of sequences as are in the file.  Exiting.\n";
	exit;
}

&fisher_yates_shuffle(\@headers);
my %keepHeaders;
for my $i (0..$num-1){
	$keepHeaders{$headers[$i]}=1;
}

open (FH,$opts{'f'}) or die "Can't open $opts{'f'}\n";
my $printflag=0;
while (my $line=<FH>){
	chomp $line;
	if ($line=~/^>/){
		$printflag = $keepHeaders{$line} ? 1 : 0;
	}
	print $line."\n" if $printflag==1;
}




sub fisher_yates_shuffle {
	my $seqs = shift;
	my $x;
	for ($x = @$seqs; --$x; ) {
		my $y = int(rand($x+1));
		next if $x == $y;
		@$seqs[$x,$y] = @$seqs[$y,$x];
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


sub varcheck {
	&usage if ($opts{'h'});
	my $errors = "";
	if (!$opts{'f'}){
		$errors .= "You have not provided a value for the -f flag\n";
	}
	elsif(!(-e $opts{'f'})) {
		$errors .= "Can't open $opts{'f'}\n";
	}
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName <-f file> [-o outfile]\n";
print <<PRINTTHIS;

Selects seqs from a fasta file randomly.

Mandatory:
-f file.  In fasta format.

Optional
-n integer.  Number of seqs to choose.  Default is 1.
-o filename.  Optional output file.  Default is STDOUT.


	
PRINTTHIS
	exit;
}