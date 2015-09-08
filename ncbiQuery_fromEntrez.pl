#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use LWP::Simple;
use XML::Simple;


my %opts;
getopts('f:',\%opts); 

my $scriptName;
if ($0 =~ /\//){
	$0 =~ /\/.*\/(.+)$/;
	$scriptName = $1;
}
else {
	$scriptName = $0;
}

&varcheck;

#print "query\torganism\tregionNote\tproteinProduct\tcdsNote\t%ident\talignLen\teValue\n";
print "entrezId\tspecies\tGene\tDesc\n";

open (LI,$opts{'f'}) or die "Can't open blast file $opts{'f'}\n";
my $pauseCount = 1;
my $loopCount = 1;
while (my $line = <LI>) {
	next if $line =~/^\s*#/;
	chomp $line;
	#print STDERR $line."\n";
	#my ($query,$hit,$ident,$alignLen,$eValue) = (split (/\t/,$line))[0,1,2,3,10];
	#my ($gi,$accession) = (split(/\|/,$hit))[1,3];
	#my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=gene&id=$line&retmode=xml";
	my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=gene&id=$line&retmode=xml";
	my $fetchDat = get("$url");
	#print $fetchDat;
	
	print $line;
	my @fLines = split("\n",$fetchDat);
	foreach my $fLine (@fLines){
		if ($fLine=~/<Org-ref_taxname>(.*)<\/Org-ref_taxname>/){
			print "\t".$1;
		}
		if ($fLine=~/<Gene-ref_locus>(.*)<\/Gene-ref_locus>/){
			print "\t".$1;
		}
		if ($fLine=~/<Gene-ref_desc>(.*)<\/Gene-ref_desc>/){
			print "\t".$1;
		}
		
	}
	print "\n";

	
#	my ($cdsNote,$proteinProd,$regionNote) = ("","","");
	
#	my $xmlParser = new XML::Simple;
#	my $xml = $xmlParser->XMLin($fetchDat);	
=begin
	my @features = @{$xml->{'GBSeq'}->{'GBSeq_feature-table'}->{'GBFeature'}};	
	foreach my $featureHash (@features){
		my @featureQuals;
		if ($featureHash->{'GBFeature_key'} =~ /CDS/i){
			if ($featureHash->{'GBFeature_quals'}->{'GBQualifier'}){
				if (ref($featureHash->{'GBFeature_quals'}->{'GBQualifier'}) eq "HASH"){
					my @quals = keys(%{$featureHash->{'GBFeature_quals'}->{'GBQualifier'}});
					$cdsNote = "ERROR-Too many qual types:".join(":",@quals);
				}
				else {
					foreach my $fQuals (@{$featureHash->{'GBFeature_quals'}->{'GBQualifier'}}){
						if($fQuals->{'GBQualifier_name'} =~ /note/){
							$cdsNote = $fQuals->{'GBQualifier_value'};
						}
					}
				}
			}
		}
		if ($featureHash->{'GBFeature_key'} =~ /region/i){
			if ($featureHash->{'GBFeature_quals'}->{'GBQualifier'}){
				if (ref($featureHash->{'GBFeature_quals'}->{'GBQualifier'}) eq "HASH"){
					my @quals = keys(%{$featureHash->{'GBFeature_quals'}->{'GBQualifier'}});
					$regionNote = "ERROR-Too many qual types:".join(":",@quals);
				}
				else {
					foreach my $fQuals (@{$featureHash->{'GBFeature_quals'}->{'GBQualifier'}}){
						if($fQuals->{'GBQualifier_name'} =~ /note/){
							$regionNote = $fQuals->{'GBQualifier_value'};
						}
					}
				}
			}
		}
		if ($featureHash->{'GBFeature_key'} =~ /protein/i){
			if ($featureHash->{'GBFeature_quals'}->{'GBQualifier'}){
				if (ref($featureHash->{'GBFeature_quals'}->{'GBQualifier'}) eq "HASH"){
					my @quals = keys(%{$featureHash->{'GBFeature_quals'}->{'GBQualifier'}});
					$proteinProd = "ERROR-Too many qual types:".join(":",@quals);
				}
				else {
					foreach my $fQuals (@{$featureHash->{'GBFeature_quals'}->{'GBQualifier'}}){
						if($fQuals->{'GBQualifier_name'} =~ /product/){
							$proteinProd = $fQuals->{'GBQualifier_value'};
						}
					}
				}
			}
		}
		
	}
	my $organism = $xml->{'GBSeq'}->{'GBSeq_source'};
	#my $definition = $xml->{'GBSeq'}->{'GBSeq_definition'};
	
	#print "$query\t$organism\t$regionNote\t$proteinProd\t$cdsNote\t$ident\t$alignLen\t$eValue\n";
	
	
=cut	
	
	
	if ($pauseCount++ > 2){
		sleep(1);
		$pauseCount = 1;
	}
	#print $fetchDat."\n";
		
	
}






sub varcheck {
	my $errors = "";
	if (!$opts{'f'}){
		$errors .= "-f flag not provided\n";
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
	
	print "\nusage: perl $scriptName <-f blastOut>\n";
print <<PRINTTHIS;
This program fetches additional information from NCBI based on gi number.

-f File containing tabular blast output (-m 8)
	
PRINTTHIS
	exit;
}
