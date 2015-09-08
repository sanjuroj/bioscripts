#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('r:q:f:m:t:i:d:e:n:',\%opts); 

my $insertCol;

&varcheck;


my $na = $opts{'n'};
$na //= 'NA';

my $querydelim = $opts{'d'} || "\t";
my $dbdelim = $opts{'e'} || "\t";
my %lookupTable;

my $findCol = $opts{'f'};
my $matchCol = $opts{'m'};
my $returnCol = $opts{'t'};
my @returnCols = @{parseCols($returnCol)};


open (LOAD,$opts{'r'}) or die "Can't open $opts{'r'}\n";
while (my $line = <LOAD>) {
	next if $line=~/^[\r\n]+$/;
	next if $line =~ /^\s*#/;
	chomp $line;
	my @spl = split (/$dbdelim/,$line);
	if (@spl < $matchCol) {
		print STDERR "The column you are searching ($matchCol) doesn't exist\n";
		exit;
	}
	my @returnTexts;
	foreach my $col (@returnCols) {
		if (@spl < $col) {
			print STDERR "The column you are returning ($returnCol) doesn't exist\n";
			exit;
		}
		else {
			push(@returnTexts,$spl[$col-1])
		}
		
	}
	$lookupTable{lc($spl[$matchCol-1])} = join("\t",@returnTexts);
	#print "key=".lc($spl[$matchCol-1]).", val=".lc($spl[$returnCol-1])."\n";
}
close LOAD;


open (REF, $opts{'q'}) or die "Can't open $opts{'q'}\n";
while (my $line = <REF>){
	chomp $line;
	#print "line=".$line."\n";
	next if $line=~/^[\s\n\t]*$/;
	
	my @spl = split (/$querydelim/,$line);
	if ($insertCol == -1){
		$insertCol = @spl+1;
	}
	
	#print "spl=".@spl."matchcol=$findCol\n";
	if (@spl < $findCol) {
		print STDERR "The column you are using as a reference ($findCol) doesn't exist\n";
		exit;
	}
	if (@spl<$insertCol-1){
		print STDERR "The column number you have given for insertion ($insertCol) is too large\n";
		print STDERR "There are only ".@spl." columns in your reference file\n";
		exit;
	}
	my $findThis = $spl[($findCol-1)];
	my $foundVal = $lookupTable{lc($findThis)} || $na;
	
	for (my $i = 0; $i < ($insertCol-1); $i++){
		print $spl[$i]."$querydelim";
	}
	print "$foundVal";
	for (my $i = $insertCol-1; $i < @spl; $i++){
		
		print "$querydelim"."$spl[$i]";
	}
	print "\n";
	
	
}




sub parseCols {
	my $colstring = shift;
	my @colList;
	my @parts = split(",",$colstring);
	foreach my $part (@parts) {
		if ($part =~ /\-/) {
			my @cols = split("-",$part);
			push (@colList,$cols[0]..$cols[1])
		}
		else {
			push(@colList,$part)
		}
	}
	
	foreach my $col (@colList) {
		if ($col !~ /^\d$/) {
			print "-t input must be in the form 'a-b,n-m', and must resolve to positive integers.  Exiting. \n";
			exit;
		}
	}
	
	@colList = sort @colList;
	return \@colList
}



sub varcheck {
	my $errors = "";
	if (!$opts{'r'}) {
		$errors .= "You must enter a reference file (-r)\n";
	}
	elsif (!(-e $opts{'r'})) {
		$errors .= "The $opts{'r'} file doesn't exist\n";
	}
	
	if (!$opts{'q'}) {
		$errors .= "You must enter a query file (-q)\n";
	}
	elsif (!(-e $opts{'q'})) {
		$errors .= "The $opts{'q'} file doesn't exist\n";
	}
	
	if (!$opts{'f'}  || $opts{'f'} =~ /\D/ || $opts{'f'} < 1) {
		$errors .= "You haven't entered a number for -f or it is invalid\n";
	}
	if (!$opts{'t'})  {
		$errors .= "You haven't entered a number for -t or it is invalid\n";
	}
	if (!$opts{'m'}  || $opts{'m'} =~ /\D/ || $opts{'m'} < 1) {
		$errors .= "You haven't entered a number for -m or it is invalid\n";
	}
	if ($opts{'i'}){
		if ($opts{'i'} =~ /\D/ || $opts{'i'} < 1) {
			$errors .= "The -i option must be a valid column number\n";
		}
		else {
			$insertCol = $opts{'i'};
		}
	}
	else {
		$insertCol = "-1";
	}
	
	
	
	
	if ($errors ne "") {
		print $errors;
		&usage;
	}
}

sub usage{
	print STDERR "\nusage: perl vlookup.pl -r <filename> -q <filename> (-f,m,t <int>) [-i int]\n";
	print STDERR "\nUses one file as a referece db.  Adds a column to the query file\n";
	print STDERR "based on a match to a column referenced in the reference file (like excel vlookup function)\n";
	print STDERR "\nMandatory:\n";
	print STDERR "-r file to be used as db reference\n";
	print STDERR "-q file to be used as the query source\n";
	print STDERR "-f the column in the query file that you want to match in the reference file\n";
	print STDERR "-m the column in the reference file to be matched\n";
	print STDERR "-t the column in the reference file that should be returned if there is a match\n";
	print STDERR "\nOptional:\n";
	print STDERR "-i the new column in the query file that will contain the matches (Defaults to new column).\n";
	print STDERR '-d the column delimiter for the query file. Default="\t"'."\n";
	print STDERR '-e the column delimiter for the query file. Default="\t"'."\n";
	print STDERR "-n null value string.  Default=\"NA\"\n";
	print STDERR "\n";
	print STDERR "Example:  vlookup.pl -r prices.txt -q quant.txt -f 1 -m 1 -t 3 -i 2\n";
	print STDERR "The file quant.txt contains item ids in column 1 and quantities in column 2.\n";
	print STDERR "prices.txt contains item ids in column 1 and prices in column 3.  The script\n";
	print STDERR "will loop through the item ids in column 1 of quant.txt, find corresponding\n";
	print STDERR "item ids in column 1 of prices.txt, and insert the associated price from column 3\n";
	print STDERR "of prices.txt into quant.txt.  Becase the -i 2 flag has been used, the prices\n";
	print STDERR "will be inserted into column 2 of quant.txt, in between the item ids and quantities.\n";
	print STDERR "\n\n";
	print STDERR "Note:  Searches are case insenstive. Also, the data being searched for is loaded into memory,\n";
	print STDERR "so very large files might eat your server.\n";
	exit;
	
}
