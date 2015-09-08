#!usr/bin/perl;



sub loadFasta{
	my $fName = shift;
	open (FH,$fName) or die "Can't open $fName\n";
	my %returnHash;
	my @order;
	
	my $sequence = "";
	my $header = "";
	my $desc = "";
	while (my $line = <FH>){
		next if ($line =~ /^\n+$/);
		chomp $line;
		if ($line =~ />/){
			my @headerPieces = split(/\s/,$line,2);
			$headerPieces[0] =~ s/^>//;
			if ($sequence ne "" and $header ne "") {
				$returnHash{$header}->{'seq'} = $sequence;
				$returnHash{$header}->{'desc'} = $desc;
			}
			$header = $headerPieces[0];
			$desc = $headerPieces[1] || "";
			$order[@order] = $headerPieces[0];
			$sequence = "";
		}
		else {
			$sequence .= $line;
		}

		if (eof FH) {
			$returnHash{$header}->{'seq'} = $sequence.$line;
			$returnHash{$header}->{'desc'} = $desc;
		}
	}
	
	
	return (\%returnHash,\@order);
	
}


my @sorted = sort {$hashTable{$a} cmp $hashTable{$b}} keys %hashTable; #sorts according to the values, not the keys

sub handle_filePath {
   my $fileName = shift;
   my $suffix = "";
   my $filePath = "";
   
   if ($clusterFile =~ /\//) {
	  $clusterFile =~ /(.+\/)(.+)$/;
	  $fileName = $2;
	  $filePath = $1;
   }
   
   if ($fileName =~ /\./) {
	 $fileName =~ /(.+)\.(.+)$/;
	 $suffix = ".$2";
	 $fileName = $1;
   }
   
   return $filePath.$fileName."_clust".$suffix;
}


sub monge {
   my $text = shift;
   chomp $text;
   $/ = "\r";
   chomp $text;
   $/ = "\n";
   return $text;
}