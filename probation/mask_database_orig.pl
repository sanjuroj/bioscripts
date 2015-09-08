#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/cgrb/cgrblib-dev/perl5';
use ASRP::DbQueryASRP;

#my $dbh = new DbQueryASRP(db=>'smallRNA-lyrata_new');
my $dbh = new DbQueryASRP(db=>'smallRNA-new');
$dbh->open_connection;
my $sth = $dbh->new_sth;

my $database = shift;
my $outfile = shift;

if (!$database || !$outfile) {
	print "Usage: mask_database.pl <Database - FASTA format> <output file>\n\n";
	exit 0;
}

my ($sql, @mirs, %db, $name, $seq);

open (DB, $database) or die "Cannot open sequence database ($database): $!\n\n";
my $step = 0;
while (my $line = <DB>) {
	chomp $line;
	if ($step == 0) {
		if ($line =~ /\>(.+)/) {
			$name = $1;
			$step = 1;
		}
	} elsif ($step == 1) {
		if ($line =~ /\>(.+)/ || eof(DB)) {
			if (eof(DB)) {
				$seq .= $line;
			}
			$db{$name} = $seq;
                        next if (eof(DB));
                        $name = $1;
                        undef($seq);
		} else {
			$seq .= $line;
                }
	}
}
close DB;

=begin
$sql = "SELECT * FROM `microRNA_loci_dev`";
$dbh->query($sth, $sql, "DIE");
while (my $row = $dbh->results($sth, "hash")) {
	#my $chrom = $db{$row->{'accession'}};
	my $chrom = $db{$row->{'chromNum'}};
	my $mask = 'N' x length($row->{'stem'});
	substr($chrom,($row->{'stem_start'} - 1),length($row->{'stem'}),$mask);
	#$db{$row->{'accession'}} = $chrom;
	$db{$row->{'chromNum'}} = $chrom;
	#$row->{'stem'} =~ s/U/T/g;
	#if ($row->{'strand'} == -1) {
	#	$row->{'stem'} = reverse($row->{'stem'});
	#	$row->{'stem'} =~ tr/ATGC/TACG/;
	#}
	#my $mask = 'N' x length($row->{'stem'});
	#$chrom =~ s/$row->{'stem'}/$mask/ig;
	#$db{$row->{'accession'}} = $chrom;
}
=cut

$sql = "SELECT * FROM `features` WHERE `category_id` >= 7 AND `category_id` <= 10";
#$sql = "SELECT * FROM `featuresv8` WHERE `category_id` >= 7 AND `category_id` <= 10";
$dbh->query($sth, $sql, "DIE");
while (my $row = $dbh->results($sth, "hash")) {
	next if (!$db{"scaffold_$row->{'chromNum'}"});
	my $chrom = $db{"scaffold_$row->{'chromNum'}"};
	#my $chrom = $db{$row->{'chromNum'}};
	my $mask = 'N' x ($row->{'end'} - $row->{'start'} + 1);
	substr($chrom,($row->{'start'} - 1),length($mask),$mask);
	#$db{"scaffold_$row->{'chromNum'}"} = $chrom;
	$db{$row->{'chromNum'}} = $chrom;
}
$sql = "SELECT * FROM `features` WHERE `category_id` >= 18 AND `category_id` <= 41";
#$sql = "SELECT * FROM `featuresv8` WHERE `category_id` >= 18 AND `category_id` <= 35";
$dbh->query($sth, $sql, "DIE");
while (my $row = $dbh->results($sth, "hash")) {
	next if (!$db{"scaffold_$row->{'chromNum'}"});
	my $chrom = $db{"scaffold_$row->{'chromNum'}"};
	#my $chrom = $db{$row->{'chromNum'}};
	my $mask = 'N' x ($row->{'end'} - $row->{'start'} + 1);
	substr($chrom,($row->{'start'} - 1),length($mask),$mask);
	#$db{"scaffold_$row->{'chromNum'}"} = $chrom;
	$db{$row->{'chromNum'}} = $chrom;
}
$sql = "SELECT * FROM `features` WHERE `category_id` >= 44 AND `category_id` <= 45";
#$sql = "SELECT * FROM `features` WHERE `category_id` >= 29 AND `category_id` <= 31";
$dbh->query($sth, $sql, "DIE");
while (my $row = $dbh->results($sth, "hash")) {
	next if (!$db{"scaffold_$row->{'chromNum'}"});
	my $chrom = $db{"scaffold_$row->{'chromNum'}"};
	#my $chrom = $db{$row->{'chromNum'}};
	my $mask = 'N' x ($row->{'end'} - $row->{'start'} + 1);
	substr($chrom,($row->{'start'} - 1),length($mask),$mask);
	#$db{"scaffold_$row->{'chromNum'}"} = $chrom;
	$db{$row->{'chromNum'}} = $chrom;
}

open (OUT, ">$outfile");
while (my ($name, $chrom) = each(%db)) {
	print OUT "\>$name\n$chrom\n";
}
close OUT;
exit;
