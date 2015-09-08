#!/usr/bin/perl
#
#v1: generates config files
#v2: added ability to run loop through list and run alignDraw
######################################################

use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('p:t:c:i:a:v:leh',\%opts); 

&varcheck;

#get name substitutions
my $nameSubFile = "/raid3/carrington/jogdeos/carrington/ppr/arabPPRanalys/seqDataFiles/list_alyNameToShortName";
open (NSUB,$nameSubFile) or die "Can't open $nameSubFile\n";
my %nameSubs;
while (my $line=<NSUB>){
	chomp $line;
	my ($old,$new) = split("\t",$line);
	$nameSubs{$old}=$new;
}

my $scriptPath = "/raid3/carrington/jogdeos/programs/alignDraw.pl";
my $errors = "";

open (PF,$opts{'p'}) or die "Can't open $opts{'p'}\n";
my @params = <PF>;
close PF;

open (TF,$opts{'t'}) or die "Can't open $opts{'t'}\n";
my @template = <TF>;
close TF;

my $confDir = $opts{'c'};
$confDir =~ s/\/$//;

my $alignDir = $opts{'a'};
$alignDir =~ s/\/$//;

my $imageDir = $opts{'i'};
$imageDir =~ s/\/$//;
	
if ($opts{'e'}){
	my $cmd = "rm $confDir/* -f";
	`$cmd`;
	$cmd = "rm $imageDir/* -f";
	`$cmd`;
}
	
	

foreach my $pLine (@params){
	next if $pLine =~ /^[\n\r\s]+$/;
	chomp $pLine;
	my ($athParam,$alyParam) = split("\t",$pLine);
	my $alyLabel = $nameSubs{$alyParam} || $alyParam;
	my $athLabel = $nameSubs{$athParam} || $athParam;
	my $confFile;
	my $shortName = substr($alyParam,0,15);
	if ($nameSubs{$alyParam}){
		$confFile ="$confDir/$athParam--$shortName--$nameSubs{$alyParam}.conf";
	}
	else{
		$confFile ="$confDir/$athParam--$alyParam.conf";
	}
	
	open (OF,">$confFile") or die "Can't open $confFile\n";
	my %subList = ('REF1_NAME' => $athParam, 'REF2_NAME' => $alyParam,
				   'REF1_LABEL' =>$athLabel, 'REF2_LABEL' => $alyLabel);
	$subList{'ALIGNMENT_SOURCE'} = "$alignDir/$athParam--$alyParam"."_align.fa";
	
	#print "athparam=$athParam,alyparam=$alyParam\n";
	my @templateLines = @template;
	foreach my $tLine (@templateLines){
		foreach my $sl (keys %subList){
			$tLine =~ s/$sl/$subList{$sl}/;
		}
		print OF $tLine;
	}
	
	close OF;
	
}



exit if $opts{'l'};

opendir(DIR,$confDir);
my @files = readdir(DIR);
closedir(DIR);
foreach my $file (@files){
	next if $file =~/^\.+$/;
	my $outFile = $file;
	$outFile =~ s/.conf$/.png/;
	
	my $cmd = "$scriptPath -C $confDir/$file -o $imageDir/$outFile";
	$cmd .= " -v $opts{'v'}" if $opts{'v'};
	print $cmd."\n";
	`$cmd`;
	print STDERR "$file complete\n";
	
}

print STDERR $errors;

sub varcheck {
	&usage if ($opts{'h'});
	my $errors = "";
	if (!$opts{'p'}){
		$errors .= "You have not provided a value for the -p flag\n";
	}
	elsif(!(-e $opts{'p'})) {
		$errors .= "Can't open $opts{'p'}\n";
	}
	
	if (!$opts{'t'}){
		$errors .= "You have not provided a value for the -t flag\n";
	}
	elsif(!(-e $opts{'t'})) {
		$errors .= "Can't open $opts{'t'}\n";
	}
	
	if (!$opts{'c'}){
		$errors .= "You have not provided a value for the -c flag\n";
	}
	elsif(!(-d $opts{'c'})) {
		$errors .= "The input you provided for -c is not a directory\n";
	}
	
	if (!$opts{'a'}){
		$errors .= "You have not provided a value for the -a flag\n";
	}
	elsif(!(-d $opts{'a'})) {
		$errors .= "The input you provided for -a is not a directory\n";
	}
	
	if (!$opts{'i'}){
		$errors .= "You have not provided a value for the -i flag\n";
	}
	elsif(!(-d $opts{'i'})) {
		$errors .= "The input you provided for -i is not a directory\n";
	}
	
	
	if ($opts{'v'} and -e $opts{'v'}){
		`rm $opts{'v'} -f`;
	}
	
	if ($errors ne "") {
		print "\n$errors";
		&usage;
	}
}

sub usage{
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print "\nusage: perl $scriptName <-p file> <-t file> <-c dir> <-i dir> [-e,-l, -v]\n";
print <<PRINTTHIS;

Creates conf files for use with alignDraw and then runs alignDraw on them

Mandatory:
-p tab delimted list of paramters.  2 columns, the first for REF1 and 2nd for REF2.
-t template for the conf file
-a directory in which pairwise alignemnts are found
-c output direcotry for conf files
-i output directory for image files

Optional:
-e (no value) eliminates all data from the conf and image directories before running.
-l (no value) will limit the output to just the conf files
-v filename. Verbose output, will print status commands to STDERR and will dump alignment
	info into file specified.  Existing file with that name will be deleted.
	
PRINTTHIS
	exit;
}