#!usr/bin/perl;
use strict;

sub usage()
{
   print STDERR q
   ( Usage: snapSort.pl <SNAPGene.gff> 
   
	   Does a multifield sort on a .gff snap gene predication file.
	   
       Sorts in the following order:  scaffold, gene id number, gene or 
       exon, and start position.  Exact field layout is as follows:
       0 - Scaffold_<number>
       2 - the text 'gene' or 'exon'
       3 - start position
       4 - stop position
       6 - strand direction (i.e. + or -)
       8 - gene number as part of a longer text field where the number can be
            extracted as the fourth element if it is split by '_' and ';'
	   
   );
   exit;
}

if ( ( @ARGV == 0 ) || $ARGV[0] eq "-h" )   #no arguments or help option
{
      &usage();
}


open (FILE,$ARGV[0]);
my @lines = <FILE>;
close FILE;
#print (@lines);
#print ("\n\n");

my @orderedSnap = sort msort @lines;

#my @tempFile = split(/./,$ARGV[0]);
#my $oFile = $tempFile[0],"_sorted.gff";
#print $oFile;
print @orderedSnap;

sub msort{
	my ($aScaf,$aStart, $aDir, $aID) = (split(/\t/,$a))[0,3,6,8];
	my ($bScaf,$bStart, $bDir, $bID) = (split(/\t/,$b))[0,3,6,8];
	my @temp = split(/_/,$aScaf);
    $aScaf=$temp[1];
    @temp = split(/_/,$bScaf);
    $bScaf=$temp[1];
    @temp = split(/[_;]/,$aID);
    my $aNum = $temp[2]+0;
    @temp = split(/[_;]/,$bID);
    my $bNum = $temp[2]+0;
    #print "\nnum=",$aNum,"num=",$bNum,"\n";
    #print "\nascaf=",$aScaf,",gene=",$aGene,",start=",$aStart,",stop=",$aStop,",dir=",$aDir,",num=",$aNum,"\n";
    if ($aDir eq "-" && $bDir eq "-"){
        $aScaf <=> $bScaf || $aNum <=> $bNum || $bStart <=> $aStart;
    }
    else{
        $aScaf <=> $bScaf || $aNum <=> $bNum || $aStart <=> $bStart;
    }
}


