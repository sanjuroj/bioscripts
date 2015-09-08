#!/usr/bin/perl
################################################################################
#  SCRAPE 1.0
#
#  Copyright 2010
#
#  Larry Wilhelm
#  Dee Denver
#  Todd Mockler
#
#  Department of Botany and Plant Pathology
#  Center for Genome Research and Biocomputing
#  Computational and Genome Biology Initiative
#  Oregon State University
#  Corvallis, OR 97331
#
#
# This program is not free software; you can not redistribute it and/or
# modify it in any way.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
################################################################################
use strict;
use Cwd;
use Getopt::Std;

#########################################################
# Variable Declarations                                 #
#########################################################

# External program names that this script depends on...
my $VH  = "velveth";
my $VG  = "velvetg";
my $AB  = "/local/cluster/abyss/bin/ABYSS";
my $ED  = "/local/cluster/edena2.1.1_linux64/edena";
my $CAP = "cap3";

my $prog_name = "SCRAPE.pl";

use vars qw/ $opt_i $opt_s $opt_n $opt_q $opt_v $opt_w $opt_h/;
my ($input_file,$sample_size,$number_samples,$velvet_hash_size,$verbose_out);

#########################################################
# Get and verify input options...
#########################################################
getopts('hd:i:s:n:v:wd');
var_check();

#########################################################
# Start Main body of Program                            #
#########################################################

my $fname = get_file_name($input_file); # get file name from full path
my $cwd = getcwd();  # current working dir...

# make a directory for this run..

my $pid = $$;
my $out_dir = $cwd."/"."scrape_".$pid;
if (-d $out_dir){
	print STDERR "Output directory exists: $out_dir, exiting\n";
}else{
	mkdir($out_dir,0755);
	if (! -d $out_dir){
		print STDERR "\n\t\tCould not Make Directory $out_dir needed to process data! Exiting program.\n";
		exit;
	}
}

# make a log file...
my $f_log = $out_dir."/$fname.assembly_log";
open(LOG,">$f_log") or die "can't open $f_log $!\n";
print LOG "Running $prog_name at ".localtime()."\n";
print LOG "Working Directory: $out_dir\n";

# make a temporary working directory...
my $tmp_dir = make_temp_dir($out_dir); 
print "GOT HERE TMP_DIR = $tmp_dir\n";

# output for user...
my $os = "$prog_name is processing file: $input_file\n";
$os   .= "sample size = $sample_size\n";
$os   .= "number of samples = $number_samples\n";
$os   .= "velvet hash size =  $velvet_hash_size\n";
print $os;
print LOG $os;

# open a temporary file for short read contigs...
my $short_read_contigs = $out_dir."/$fname"."_sr_contigs.fa";
open (VCF, ">$short_read_contigs") or die "Can't open $short_read_contigs $!\n";

# PROCESS SAMPLE SETS
for(1..$number_samples){
	my $n = $_;
	
	my $v_out = "\nSample $n\n"; # verbose output string.
	
	print LOG "\nSample: $n\n";
	
	# FISHER-YATES SHUFFLE..
	fisher_yates($input_file,$sample_size,"$tmp_dir$n.fa");
	
	### RUN THE SHORT READ ASSEMBLERS...
	
	## VELVET
	# run velveth
	my $cmd = $VH." ".$tmp_dir." ".$velvet_hash_size." ".$tmp_dir.$n.".fa";
	my $res = `$cmd`;
	$v_out .= "VelvetH: $cmd\n";
	# run velvetg
	$cmd = $VG." ".$tmp_dir;
	$res = `$cmd`;
	$v_out .= "VelvetG: $cmd\n";
	
	## ABYSS
	#$cmd = "$AB -l32 -k25 ".$tmp_dir.$n.".fa"." -o $tmp_dir"."abyss_$n.fa 2> $tmp_dir"."tmp.stderr";
	$cmd = "$AB -k25 ".$tmp_dir.$n.".fa"." -o $tmp_dir"."abyss_$n.fa 2> $tmp_dir"."tmp.stderr";
	$res = `$cmd`;
	$v_out .= "Abyss: $cmd\n";
	
	## EDENA
	$cmd = "$ED -r ".$tmp_dir.$n.".fa -p ".$tmp_dir.$n."_ed";
	$res = `$cmd`;
	$v_out .= "Edena_1: $cmd\n";
	$cmd = "$ED -e $tmp_dir".$n."_ed.ovl -p $tmp_dir".$n."_ed_assembly";
	$res = `$cmd`;
	$v_out .= "Edena_2: $cmd\n";
	
	print LOG $v_out."\n" if $verbose_out;

	### CONSOLIDATE ALL SHORT READS INTO SINGLE FILE

	# VELVET
	open (F,$tmp_dir."contigs.fa");
	while (<F>){
		print VCF $_;
	}
	close F;
	
	# ABYSS
	open (F,$tmp_dir."abyss_$n.fa");
	while (<F>){
		print VCF $_;
	}
	close F;
	
	# EDENA
	open (F,$tmp_dir.$n."_ed_assembly_contigs.fasta");
	while (<F>){
		print VCF $_;
	}
	close F;
	
	### OUTPUT DATA FOR THE USER
	
	$cmd = "grep '>' -c ".$tmp_dir."contigs.fa"; # velvet makes this file
	$res = `$cmd`;
	chomp $res;
	print LOG "$res Velvet contigs\n";
	
	$cmd = "grep '>' -c ".$tmp_dir."abyss_$n.fa";
	$res = `$cmd`;
	chomp $res;
	print LOG "$res Abyss contigs\n";
	
	$cmd = "grep '>' -c ".$tmp_dir.$n."_ed_assembly_contigs.fasta";
	$res = `$cmd`;
	chomp $res;
	print LOG "$res Edena contigs\n";
	
}


my $cmd = "grep '>' -c $short_read_contigs";
my $res = `$cmd`;
chomp $res;
print "\nRunning CAP3 with $res short-read assembled contigs...\n";
print LOG "\nRunning CAP3 with $res short-read assembled contigs...\n";

### CAP3 

my $t_f = $tmp_dir."tmp.txt";
$cmd = $CAP." ".$short_read_contigs." > ".$t_f;
print LOG "CAP: $cmd\n" if $verbose_out;
`$cmd`;

my $cap3_contigs_file = $short_read_contigs.".cap.contigs";

my @r = split(/\n/,contig_len_dist($cap3_contigs_file));
my $longest_contig = $r[0];
print LOG scalar(@r)." Total contigs\nLongest contig is $longest_contig\n\n";
print LOG "Cap3 Contig Length Distribution....\n".join("\n",@r)."\n";


# clean up all the mess left by these programs...
print "cleaning up...\n";
$cmd = "mv $short_read_contigs".".cap.contigs ".$out_dir."/$fname".".cap.contigs";
`$cmd`;

$cmd = "rm -rf $tmp_dir";
`$cmd`;

$cmd = "rm $out_dir/*_sr_contigs*";
`$cmd`;

# get the number of contigs in the output...
$cmd = "grep '>' -c $out_dir/$fname.cap.contigs";
my $r = `$cmd`;
chomp $r;

print "SCRAPE.pl is finished!\n";
print "$r contigs were assembled, the longest of which is: $longest_contig\n";
print "Results are in file: $out_dir/$fname.cap.contigs\n";
exit(0);


################################################################################
# SUBROUTINES                                                                  #
################################################################################

sub contig_len_dist{
	my $f = shift;
	my %h;
	open (F,$f) or die "$prog_name can't get contig lengths from file: $f $!\n";
	my $fc = join('',<F>);
	close F;
	my @segs = split(/\>/,$fc);
	foreach (@segs){
		my @r = split(/\n/,$_);
		shift @r;
		my $seq = join('',@r);
		next if (!length($seq));
		$h{length($seq)}++;
	}
	my $rv;
	foreach my $k (sort {$b<=>$a} keys %h){
		$rv .= $k."\n";
	}
	return $rv;
}

sub print_contigs{
	my $f = shift;
	my @r = split(/\n/,contig_len_dist($f));
	print LOG "$f --> Velvet Contigs ".scalar(@r)."\n".join("\n",@r[0..10])."\n";
}

sub fisher_yates{
	my $file  = shift;
	my $size  = shift;
	my $out_f = shift;
	
	my @reads;
	open (F,$file) or die "can't open $file $!\n";
	while (<F>) {
		chomp $_;
		if ($_ =~ /^\>/ || $_ =~ /^\@/){
			my $hdr = substr($_,1);
			$hdr = ">".$hdr; 
			my $seq = <F>;
			chomp $seq;
			if ($seq =~ /N/ || $seq =~ /\./) {
				next;
			}
			my $v = $hdr."\t".$seq;
			push @reads, $v;
		}else{
			next;
		}
	}
	close F;
	srand;
	fisher_yates_shuffle(\@reads);
	
	open (OUT,">".$out_f) or die "$prog_name can't open output file while fisher-yates shuffling: $out_f $!\n";
	
	for (my $i=0; $i<$size; $i++) {
	    my $read_pick = $reads[$i];
	    my ($readhead,$readseq) = split(/\t/,$read_pick,2);
	    print OUT "$readhead\n$readseq\n";
	}
	close OUT;
}

sub fisher_yates_shuffle {
    my $genes = shift;
    my $x;
    for ($x = @$genes; --$x; ) {
        my $y = int(rand($x+1));
        next if $x == $y;
        @$genes[$x,$y] = @$genes[$y,$x];
    }
}


sub get_file_name{
	my $in_file = shift;
	my @path = split("/",$input_file);
	if (scalar(@path) > 1){
		return $path[scalar(@path)-1];
	}else{
		return $input_file;
	}
}

sub make_temp_dir{
	my $cur_dir = shift;
	# make a temporary working dir...
	my $tmp_dir = "$cur_dir/assemble_tmp/";
	
	if (! -e $tmp_dir){
		`mkdir $tmp_dir`;
		if (! -e $tmp_dir){
			my $os = "$prog_name attempted to make directory: $tmp_dir but failed! Exiting...\n";
			print STDERR $os;
			print LOG $os;
			exit(0);
		}
	}else{
		my $os = "$prog_name attempted to make directory: $tmp_dir, but it already exists! Exiting...\n";
		print STDERR $os;
		print LOG $os;
		exit(0);
	}
	
	return $tmp_dir;
}

sub var_check{
	if ($opt_h){
		help();
	}
	if ($opt_i){
		$input_file = $opt_i;
		die "No input file specified!, it is required\n" unless ($input_file);
		die "SCRAPE can't find or open input file: $input_file\n" unless (-e $input_file);
	}
	else {
		help();
	}
	if ($opt_s){
		$sample_size = $opt_s;
	}else{
		$sample_size = 10000;
	}
	if ($opt_n){
		$number_samples = $opt_n;
	}else{
		$number_samples = 20;
	}
	if ($opt_v){
		$velvet_hash_size = $opt_v;
	}else{
		$velvet_hash_size = 21;
	}
	if ($opt_w){
		$verbose_out = 1;
	}else{
		undef $verbose_out;
	}
	help() if (!$input_file || !$sample_size || !$number_samples);
}

##### HELP FILE ##############

sub help{
	
	print "   \n";
	print "   SCRAPE.pl is a program that assembles microreads.\n";
	print "   (Shortread Cap3 Random-sample Assembly Program)\n\n";
	print "   Usage:\n\n";
	print "   -h (flag) Displays this help information\n\n";
	print "   -i Input file        - multifasta file of microreads of uniform length (required)\n";
	print "   -s Sampling size     - number of reads to sample from input file (required)\n";
	print "   -n Number samples    - number of samples to pre-assemble (optional, default=20)\n";
	print "   -v velvet hash size  - hash size to use for Velvet (optional, default = 21)\n";
	print "   -w verbose output    - use this option to get a more verbose output in the log file\n";
	print "   \n\n";
	print "   SCRAPE.pl will create an output directory underneath the directory from which the\n";
	print "   script is called.\n\n";
	print "   This output directory is named: scrape_<pid>, where <pid> is the program id.\n\n";
	print "   When the script is finished, a log file and a file of assembled contigs can \n";
	print "   be found in the output directory. These files are named from the input file, like so:\n";
	print "   <input_file_name>.assembly_log\n";
	print "   <input_file_name>.cap.contigs\n\n";
	print "   ESTIMATING SAMPLE SIZE:\n";
	print "   \n";
	print "   As a general guideline...\n";
	print "   \n";
	print "   It is best to choose a sample size such that the number of reads provided\n";
	print "   result in ~70X coverage of the target sequence. A value for sample depth values can range from\n";
	print "   20 for small genomes to 80 for larger genomes.\n";
	print "   \n";
	print "   Total number of reads needed = (Estimated Target Size * Sample Depth) / (Read Length).\n";
	print "   \n";
	print "   However, this is only a guide. An empirical determination of the best\n";
	print "   sample size is advisable. Just run SCRAPE with a range of sampling size values\n";
	print "   and see what value produces the largest contig.\n";
	print "   \n\n";
	print "   GENERAL USAGE NOTES:\n\n"; 
	print "   SCRAPE.pl runs several microread assemblers, then uses the contigs produced\n";
	print "   by these assemblers as input for CAP3.\n\n";
	print "   SCRAPE.pl takes random samples of size 'Sample Size' from the input file.\n";
	print "   The number of samples to take is provided by the -n argument (Number samples)\n";
	print "   The randomization is done with a Fisher-Yates shuffle\n\n";
	print "   ACKNOWLEDGEMENTS:\n\n";
	print "   Author:      Larry Wilhelm\n";
	print "   Co-Authors:  Dee Denver\n";
	print "                Todd Mockler\n";
	print "                Chris Sullivan\n\n";
	print "   SCRAPE.pl was developed under the financial support of the Mockler and Denver laboratories\n";
	print "   and the high-performance computational infrastructure provided by the Center for Genome Research and Bioinformatics\n";
	print "   at Oregon State University.\n\n";
	print "   Please cite the following page if using SCRAPE.pl for publication:\n";
	print "   http://mocklerlab-tools.cgrb.oregonstate.edu/SCRAPE.html";
	print "   \n\n";
	print "   The authors owe a debt of gratitude to the creators of the following programs,\n";
	print "   without which SCRAPE.pl would not be possible:\n\n";
	print "   Edena:  http://www.genomic.ch/edena.php\n";
	print "   Velvet: http://www.ebi.ac.uk/~zerbino/velvet/\n";
	print "   ABYSS:  http://www.bcgsc.ca/platform/bioinfo/software/abyss\n";
	print "   CAP3:   http://deepc2.psi.iastate.edu/aat/cap/capdoc.html\n\n";
	exit (0);
}


