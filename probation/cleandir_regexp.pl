#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use POSIX qw( ceil floor );
use vars qw/ $opt_d $opt_e /;

#########################################################
# Start Variable declarations                           #
#########################################################

my ($indir, $expression);

#########################################################
# End Variable declarations                             #
#########################################################

#########################################################
# Start Main body of Program                            #
#########################################################

getopts('vi:d:e:');
&var_check();

opendir (DIR, $indir) or die "Cannot read directory $indir: $!\n\n";
my @dir_files = readdir DIR;
closedir DIR;

my $total_files = scalar(@dir_files);

my $count = 0;
my $file_count = 0;

foreach my $file (@dir_files) {
	next if ($file =~ /^\.+$/);
	$file_count++;
	if ($expression eq '*') {
		unlink "$indir/$file";
		$count++;
	} else {
		if ($file =~ /$expression/) {
			unlink "$indir/$file";
			$count++;
		}
	}
	my $percent = ceil(($file_count/$total_files)*100);
	$percent .= '%';
	print STDERR " $percent\r";
}

print "Deleted $count files\n\n";

exit;

#########################################################
# End Main body of Program                              #
#########################################################

#########################################################
# Start Subroutines                                     #
#########################################################

sub var_check {
	if ($opt_d) {
		$indir = $opt_d;
	} else {
		&var_error();
	}
	if ($opt_e) {
		$expression = $opt_e;
	} else {
		&var_error();
	}
}

sub var_error {
	print "\n\n";
	print " This script will delete all files in a directory that match the given expression.\n";
	print " You did not provide enough information\n";
	print " Usage: cleandir_regexp.pl -d <directory> -e <expression>\n\n";
	print " 	-d	Input directory\n";
	print " 	-e	Pattern matching expression (Case sensitive, use '*' to match all files)\n";
	print "\n\n";
	exit 0;
}

#########################################################
# End Subroutines                                       #
#########################################################

