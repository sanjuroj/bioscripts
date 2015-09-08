#!/usr/bin/perl
# author: Sanjuro Jogdeo

use strict;
use warnings;

sub usage()
{
   print STDERR q
   ( Usage: tagSelfBlast <Blast output FILE> <gene gff FILE> <min %id> <min align len>
      
    Tags blast output  
	   
   );
   exit;
}

if ( ( @ARGV == 0 ) || $ARGV[0] eq "-h" )   #no arguments or help option
{
      &usage();
}

my $blastFile=$ARGV[0];
my $geneFile = $ARGV[1];
my $minID = $ARGV[2];
my $minLen = $ARGV[3];
my $outFile = &handleFilePath($blastFile);

open ( BFILE, $blastFile ) or die "Unable to open ".$blastFile;
open (OFILE,">$outFile") or die "Unable to open ".$outFile;
open (GFILE, $geneFile) or die "Unable to open ".$geneFile;

print OFILE "subj\tquery\t%id\tresidues\t#mismatch\tgaps\tsubj_st\tsubj_stp";
print OFILE "\tquery_st\tquery_st\te-value\tbitscore\tscaff1\tstart1\tstop1\tsID";
print OFILE "\tscaff2\tstart2\tstop2\tqID\tnotSelf\tprassCrit\tpairID\tgroup\n";

my %genes;
my $paircount = 1;

#load genes
while (my $geneLine = <GFILE>) {
   my @geneSplit = split(/\t/,$geneLine);
   if (defined($geneSplit[2]) and $geneSplit[2] eq "gene"){
	  $geneSplit[8] =~ /.*ID=.*V11_(.*$)/;
	  my $geneID = $1;
	  if ($geneID =~ /;/){
		 $geneID =~ /(^.*);/;
		 $geneID = $1;
	  }
	  
	  my $geneName = "JGI_V11_".$geneID;
	  my $geneString = "$geneSplit[0]\t$geneSplit[3]\t$geneSplit[4]\t$geneID";
	  $genes{$geneName} = $geneString;
	  
   }
   
   
}
close GFILE;

my @outputArray;
my %groupHash;
my @groupArray;
my $groupIndex=1;
my %pairHash;
my $pairIndex=1;
while (my $blastLine = <BFILE>) {
   
   $blastLine = &monge($blastLine);	
   my @blastSplit = split(/\t/,$blastLine);
   my $outString = "$blastLine\t$genes{$blastSplit[0]}\t$genes{$blastSplit[1]}";
   if ($blastSplit[0] eq $blastSplit[1]){
	  $outString .= "\t0";
   }
   else {
	  $outString .= "\t1";
   }
   if ($blastSplit[2] >= $minID and $blastSplit[3] >= $minLen){
	  $outString .= "\t1";
   }
   else{
	  $outString .= "\t0";
   }
   
   #identify reciprical pairs
   if(!$pairHash{$blastSplit[0]}{$blastSplit[1]} and
	  !$pairHash{$blastSplit[1]}{$blastSplit[0]}){
	  $pairHash{$blastSplit[0]}{$blastSplit[1]} = $pairIndex++;
   }

   
   my $group1ID = -1;
   my $group2ID = -1;
   if($groupHash{$blastSplit[0]}){
	  $group1ID = $groupHash{$blastSplit[0]};
   }
   if($groupHash{$blastSplit[1]}){
	  $group1ID = $groupHash{$blastSplit[1]};
   }
   if($group1ID == $group2ID and $group1ID == -1){
	  $groupHash{$blastSplit[0]} = $groupIndex;
	  $groupHash{$blastSplit[1]} = $groupIndex;
	  $groupArray[$groupIndex] .= "\t$blastSplit[0]\t$blastSplit[0]";
	  $groupIndex++;
   }
   elsif ($group1ID > 0 and $group2ID < 0){
	  $groupHash{$group2ID} = $groupHash{$group1ID};
	  $groupArray[$group2ID] .= "\t$group2ID";
   }
   elsif ($group2ID > 0 and $group1ID < 0){
	  $groupHash{$group1ID} = $groupHash{$group2ID};
	  $groupArray[$group1ID] .= "\t$group1ID";
   }
   elsif ($group1ID > 0 and $group2ID > 0){
	  if($groupHash{$group1ID} != $groupHash{$group2ID}){
		 &combineGroups($groupHash{$group1ID},$groupHash{$group2ID})
	  }
   }
   
   $outputArray[@outputArray] = $outString;
}



foreach (@outputArray){
   my $oString = $_;
   print OFILE $oString;
   my @oArray = split(/\t/,$oString);
   
   if(defined($pairHash{$oArray[0]}{$oArray[1]})){
	  print OFILE "\t".$pairHash{$oArray[0]}{$oArray[1]};
   }
   else{
	  if(defined($pairHash{$oArray[1]}{$oArray[0]})){
		 print OFILE "\t".$pairHash{$oArray[1]}{$oArray[0]};
	  }
	  else {
		 print OFILE "FAILURE";
	  }
   }
   print OFILE "\t$groupHash{$oArray[0]}";
   
   
   print OFILE "\n";
}


sub handleFilePath {
   my $fileName = shift;
   my $suffix = "";
   my $filePath = "";
   
   if ($fileName =~ /\//) {
	  $fileName =~ /(.+\/)(.+)$/;
	  $fileName = $2;
	  $filePath = $1;
   }
   
   if ($fileName =~ /\./) {
	 $fileName =~ /(.+)\.(.+)$/;
	 $suffix = ".$2";
	 $fileName = $1;
   }
   
   return $filePath.$fileName."_taged".$suffix;
}

sub monge {
   my $text = shift;
   chomp $text;
   $/ = "\r";
   chomp $text;
   $/ = "\n";
   return $text;
}

sub combineGroups {
   my $changeGroup = shift;
   my $keepGroup = shift;
   my @changeThese = split(/\t/,$groupArray[$changeGroup]);
   for (my $i = 0; $i<@changeThese; $i++) {
	  $groupHash{$changeThese[$i]} = $keepGroup;
   }
   
   
}