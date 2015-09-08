#!usr/bin/perl;
use strict;
use warnings;


=begin

List of tests:
--test adding to a annonymous list
--test using a sort function
--test sorting nested arrays
--test nested array referencing
--test if you can do between using a<b<c (doesn't work)
--test anonymous nested hashes
--test replacing with substring
--test opening and closing output files
--test passing to subroutines by reference and by value
--test if arrays can be assigned directly to scalars
--test if a x = bool ? true : fase can trigger a subroutine
--test EOF when using file handle
--test graph module
=cut



=begin test adding to a annonymous list
my @ar1 = qw (1 100 1000 9000);
my @ar2 = qw (10 50 300 3000);
my %hash;
my %hash2;
$hash{'first'} = \@ar1;
push(@{$hash{'first'}},20000);
print join("\t",@{$hash{'first'}})."\n";
#prints 1	100	1000	9000	20000

push (@{$hash2{'first'}},"2999");
print join("\t",@{$hash2{'first'}})."\n";
#prints 2999

=cut hey, it works, 



=begin test using a sort function
my (%hash,%hash2);
$hash{'key1'}->{'first'} = 5;
$hash{'key1'}->{'second'} = 2000;
$hash{'key2'}->{'first'} = 2;
$hash{'key2'}->{'second'} = 6000;

my @keyArray = keys %hash;
my @sorted = sort sortFunc @keyArray;
print $hash{$sorted[0]}->{'first'}."\n";
print $hash{$sorted[1]}->{'first'}."\n";
print $hash{$sorted[0]}->{'second'}."\n";
print $hash{$sorted[1]}->{'second'}."\n";

sub sortFunc {
    my $aVal=$hash{$a}->{'first'};
    my $bVal=$hash{$b}->{'first'};
    return $aVal<=>$bVal;
}
=cut works just fine

=begin --test sorting nested arrays
my @ar1 = qw (1 100 1000 9000);
my @ar2 = qw (10 50 300 3000);
my @ar3 = qw (5 4 3000 6000);
my @master;
$master[0] = \@ar1;
$master[1] = \@ar2;
$master[2] = \@ar3;

for (my $i=0; $i<3; $i++) {
    print $master[$i][0]."\t";
}
print "\n";

my @sorted = sort sortFunc @master;

for (my $i=0; $i<3; $i++) {
    print $sorted[$i][0]."\t";
}
print "\n";

for (my $i=0; $i<3; $i++) {
    print $master[$i][0]."\t";
}
print "\n";

sub sortFunc {
    return $$a[0] <=> $$b[0];
}
=cut # sorts properly and doesn't change the original 



=begin --test nested array referencing
my @ar1 = qw (a b c d);
my @ar2;
$ar2[0] = \@ar1;
print $ar2[0][1]."\n";
=cut  # prints 'b'




=begin test if you can do between using a<b<c (doesn't work)
my ($a,$b,$c) = qw(1 2 3);
if ($a<$b<$c){
	print "yes\n";
}
else {
	print "no\n";
}
=cut


=begin test anonymous nested hashes
my (%hash1,%hash2);
my ($a,$b,$c,$d) = qw(scaf1 scaf2 scaf3 scaf4);
my ($s1,$p1,$s2,$p2,$s3,$p3,$s4,$p4) = qw(23 45 65 98 233 298 983 1102 2034 2983);

$hash1{$a}->{"start"} = $s1;
$hash1{$a}->{"stop"} = $p1;

print $hash1{$a}->{"stop"}."\n";

$hash2{$a}->[0] = $s1;
$hash2{$a}->[1] = $p1;

print "newtest\n";
my @ar = @{$hash2{$a}};
foreach (@ar){
	print $_."\n";
}

=cut




=begin --test replacing with substring
my $str = "abcdefghijklmnopqrstuvwxyz";
my $sub = substr($str,0,3,"88");
print "sub=$sub\nstr=$str\n";
=cut #returns str as 88def... and sub as abc






=begin--test opening and closing output files
open (TMP,">zm") or die "Can't open zm\n";
print TMP ">number 1\n";
close TMP;
open (TMP,">zm") or die "Can't open zm\n";
print TMP ">number 2\n";
close TMP;
=cut result just prints "number 2";





=begin test passing to subroutines by reference and by value
my @array = (1,2,3,4);
print "original = ".join(",",@array)."\n";
pass1(@array);
print "pass1 = ".join(",",@array)."\n";
pass2(\@array);
print "pass2 = ".join(",",@array)."\n";
pass3(\@array);
print "pass3 = ".join(",",@array)."\n";

sub pass1 {
	my @ar = shift;
	$ar[0] = "a";
}

sub pass2 {
	my $ref = shift;
	my @ar = @{$ref};
	$ar[0] = "b";
	#$subArray[0] = "2";
}

sub pass3 {
	my $ar = shift;
	@$ar[0] = "c";
	
}
=cut #only pass3 modifies the original  


=begin test if arrays can be assigned directly to scalars
my @array = qw(ksjd sidf oig iorugh);
my ($a,$b,$c,$d) = @array;
print "$a, $b, $c, $d\n";
=cut


=begin  test if a x = bool ? true : fase can trigger a subroutine
my $opt_c = 0;

my $pt = $opt_c ? "true" : error();
print "$pt\n";

sub error {
	print "error\n";
	exit;
}
=cut

=begin test EOF when using file handle
open (FH,$ARGV[0]);
while (my $line= <FH>){
	print $line;
	print "last line\n" if eof(FH);
	last if eof(FH);
	
}
=cut


=begin test graph module
use strict;
use warnings;
use Graph;

my $graph1 = Graph::Undirected -> new;
$graph1->add_vertices(1,2);
$graph1->add_edge(1,2);
$graph1->add_vertices(3,4);
$graph1->add_edge(3,4);
$graph1->add_vertices(5,6);
$graph1->add_edge(5,6);
$graph1->add_vertices(1,4);
$graph1->add_edge(1,4);

my @groups = $graph1->connected_components();

my $i=1;
foreach(@groups){
	my @gList = @{$_};
	print "group $i\n";
	foreach(@gList){
		print "$_\n";
	}
	print "\n";
	$i++;
}

=cut


