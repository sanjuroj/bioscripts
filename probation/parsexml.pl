#!/usr/bin/perl

use XML::Simple;
use XML::Twig;
use strict;
use warnings;

my $fileName = $ARGV[0];

my $newx = new XML::Twig (
		twig_handlers => {trace => \&trace});

$newx->parsefile($fileName);
#$newx->flush;

sub trace{
	my ($twig,$trace) = @_;
	
	my $accession = $trace->first_child("TI")->text;
	my $name = $trace->first_child("TRACE_NAME")->text;
	print $accession."\t".$name."\n";
	$twig->purge;
}


=begin

my $newx = new XML::Simple (KeyAttr=>'TI');

my $doc = $newx->XMLin($fileName);
#print "array sb".$doc->{'trace'}."\n";
my %xmlHash = %{$doc->{'trace'}};
foreach my $element (keys %xmlHash){
	print "$element\t";
	print $xmlHash{$element}->{'TRACE_NAME'}."\n";
}
=cut