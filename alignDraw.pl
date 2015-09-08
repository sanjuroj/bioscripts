#!/usr/bin/perl
#########################################################
#
#v6: Added vLine glyph
#########################################################
# To do list:
# -handle features that span entire introns
# -ability to handle other combinations of alignments (e.g. transcript is genomic and feature is algined to spliced transcript)
# -I don't think the matching of the attribs section is very well handled, should probably fix
# -filter is case insenstive, may want to fix but may not
#########################################################

use strict;
use warnings;
use lib '/raid3/carrington/jogdeos/programs/software/CASHX_2.3';
use lib '/home/cgrb/cgrblib-dev/perl5';
use Cwd;
use Carp;
use Getopt::Std;
use CASHX::Configuration;
use CASHX::ReadCASHX;
use POSIX qw(ceil floor);
use GD::Simple;
use Config::Tiny;


#########################################################
# Start Variable declarations                           #
#########################################################



my (%opt, $svgFile, $chromNum, $alignment, $refSpecies, $window, $step, %pos, %exon);
getopts('C:o:v:', \%opt);

&var_check();


#$alignment = "ATH_ALY";
#my $mercatorConfFile = "/raid3/carrington/jogdeos/programs/software/CASHX_2.0/conf/mercator.conf";
#my $mercConf = new Configuration(file => $mercatorConfFile);
#croak("Error: alignment $alignment does not exist in conf file\n") if(($mercConf->get($alignment,'species1')) eq -1);
#croak("Error: alignment $alignment does not exist in conf file\n") if(($mercConf->get($alignment,'species2')) eq -1);

#my $species1 = $mercConf->get($alignment,'species1');
#my $species2 = $mercConf->get($alignment,'species2');


my $cashxConfFile = "/raid3/carrington/jogdeos/programs/software/CASHX_2.3/conf/CASHX.conf";
my $alignConf = Config::Tiny->new;
$alignConf = Config::Tiny->read($opt{'C'});
#my $Conf = new Configuration(file => $cashxConfFile);
#my $ReadCASHX1 = new ReadCASHX(conf => $cashxConfFile, species => $species1);


#get tracks and track order from alignConfig file
my $trackConfigs;
my @trackOrder;
foreach my $c (keys %{$alignConf}){
    if ($c ne "_"){
        $trackConfigs->{$c} = $alignConf->{$c};
        push(@trackOrder,$c);
    }
}

#foreach (keys %{$trackConfigs->{'ATHPPR_6FRAME_LS'}}){
#	print STDERR $_.":";
#}
#print STDERR "\n";

@trackOrder = sort {$trackConfigs->{$a}->{'trackOrder'}<=>$trackConfigs->{$b}->{'trackOrder'}} @trackOrder;

my $params = $alignConf->{'_'};
my $tickLength = $params->{'defaultTickLength'};
my $defaultTrackHeight = $params->{'defaultTrackHeight'};
my $defaultGlyphHeight = $params->{'defaultGlyphHeight'};
my $defaultFontSize = $params->{'defaultFontSize'};
my $padLeft = $params->{'padLeft'};
my $padRight = $params->{'padRight'};
my $padTop = $params->{'padTop'};
my $padBottom = $params->{'padBottom'};
my $nameSubFile = $params->{'nameSubs'} || "";
my %nameSubs;
if ($nameSubFile ne ""){
	open (NS,$nameSubFile);
	while (my $line=<NS>){
		next if $line=~/^#/;
		next if $line=~/^[\r\n\s]+$/;
		chomp $line;
		my ($orig,$new) = split ("\t",$line);
		$nameSubs{$orig}=$new;
	}
}



my %color;

#degradome categories
$color{0} = 'red';
$color{1} = 'gradient38';
$color{2} = 'limegreen';
$color{3} = 'gradient29';
$color{4} = 'lightslategray';

#sRNA size classes
$color{19} = 'lavender';
$color{20} = 'turquoise';
$color{21} = 'blue';
$color{22} = 'green';
$color{23} = 'fuchsia';
$color{24} = 'red';
$color{25} = 'darkred';
$color{26} = 'black';
$color{27} = 'black';
$color{28} = 'black';
$color{29} = 'black';
$color{30} = 'black';

my %gffFields = ('seqid'=>0,'source'=>1,'type'=>2,'start'=>3,'end'=>4,
                 'score'=>5,'strand'=>6,'phase'=>7,'attribs'=>8);
my @gffFields = qw (seqid source type start end score strand phase attribs);
my $genomeToTranscriptMap;
my $normFactor = 1000000;
my $errors = "";

#########################################################
# End Variable declarations                             #
#########################################################

#########################################################
# Start Main body of Program                            #
#########################################################


#retrieve track data from various sources
my @refTracks = grep (/REF/,keys %{$trackConfigs});
my @plotTracks = grep (!/REF/,keys %{$trackConfigs});


#load references first because they are needed for loading the tracks.  then combine
#the hash for ease of use.

#trackData structure is $trackData{REF}->{'posiitonArray'}->@positions[%hash].
#The hash must contain seqid, start, end, score, strand, and attribs
my $trackData = &getData($trackConfigs,\@refTracks);
my $tempData = &getData($trackConfigs,\@plotTracks);
while (my($key, $value) = each %{$tempData}){
	$trackData->{$key} = $value;
}
$tempData = "";

my $iheight = 0;
foreach my $track (@trackOrder){
	if (!$trackConfigs->{$track}->{'trackHeight'}){
		$trackConfigs->{$track}->{'trackHeight'} = $defaultTrackHeight;
	}
	if (!$trackConfigs->{$track}->{'glyphHeight'}){
		$trackConfigs->{$track}->{'glyphHeight'} = $defaultGlyphHeight;
	}
	$iheight += $trackConfigs->{$track}->{'trackHeight'};
	#print STDERR "track, th, gh =  $track, $trackConfigs->{$track}->{'trackHeight'}, $trackConfigs->{$track}->{'glyphHeight'}\n"
	#print "iheight=$iheight, track=$track\n";
}

$iheight += $padTop + $padBottom;  # add a bit for the padding
#print "last iheight $iheight\n";
my $iwidth = $params->{'iwidth'};
#my $y_min = $params->{'y_min'};
#my $y_max = $params->{'y_max'};
#my $y_scale = ($track_height / ($y_max - $y_min));

my %skipTracks;
#
#foreach my $track (keys %{$trackConfigs}){
#	if ($trackConfigs->{$track}->{'possibleNull'} && $trackConfigs->{$track}->{'possibleNull'} == 1){
#		my @trackPos = @{$trackData->{$track}->{'positionArray'}};
#		if (@trackPos == 0){
#			$iheight -= $trackConfigs->{$track}->{'trackHeight'};
#			$skipTracks{$track} = 1;
#			#print "new iheight=$iheight, skipping $track for $trackConfigs->{$track}->{'trackHeight'}\n";
#		}
#	}
#}



#get the alignment information.  $alignmentMatrix is a has of ref1 aligned residues
#and ref2 aligned residues.  $alignRef is the alignment itself as a hash keyed by the transcript names.

my ($alignMatrix,$alignRef) = &makeAlignMatrix();

#use the median of the aligned positions to shift one of the references so that the
#alignment is straighter.  Then calculate the scaling required if the plotted lengths are
#larger than the image width. If the image width is much larget than the references,
#shorten the image width

my @ordRef1Pos = sort{$a<=>$b} keys %{$alignMatrix};
my @ordRef2Pos;
foreach my $k (keys %{$alignMatrix}){
	push (@ordRef2Pos,$alignMatrix->{$k}->{'pos'});
}
@ordRef2Pos = sort {$a<=>$b} @ordRef2Pos;
my ($ref1mid,$ref2mid); # need to declare these ahead of time or the sum will not work
my $ref1Len = $trackData->{'REF1'}->{'length'};
my $ref2Len = $trackData->{'REF2'}->{'length'};
$ref1mid += $_ foreach @ordRef1Pos;
$ref2mid += $_ foreach @ordRef2Pos;
$ref1mid = ($ref1mid/@ordRef1Pos)+$ordRef1Pos[0];
$ref2mid = ($ref2mid/@ordRef2Pos)+$ordRef2Pos[0];
#print "ref1mid,ref2mid=$ref1mid,$ref2mid\n";
my $alignPad = ceil(abs($ref1mid-$ref2mid)/2);
my ($ref1AlignPad,$ref2AlignPad) = (0,0);
if ($ref1mid < $ref2mid){
	$ref1AlignPad = ceil($alignPad);
}
else{
	$ref2AlignPad = ceil($alignPad);
}
#print "alignpad=$alignPad\n";
#print "ref1end=$ordRef1Pos[@ordRef1Pos-1], ref1beg=$ordRef1Pos[0], ref2end=$ordRef2Pos[@ordRef2Pos-1], ref2beg=$ordRef2Pos[0]\n";

$ref1Len += $ref1AlignPad;
$ref2Len += $ref2AlignPad;
my $width = $ref1Len > $ref2Len ? $ref1Len : $ref2Len;
my $xScale = 1;
if ($width > ($iwidth-$padLeft-$padRight)){
	$xScale = (($iwidth-$padLeft-$padRight) / ($width + 1));
}
elsif ($width<($iwidth-$padLeft-$padRight)){
	$iwidth = $width + $padLeft + $padRight;
}
my $defaultPenSize = $xScale < 1 ? $xScale : 1;
#print "defaultPenSize = $defaultPenSize\n";

#instantiate the drawing tool
my $img = GD::Simple->new($iwidth,$iheight);
$img->font('Arial');
$img->fontsize($defaultFontSize);
my $current_track_position = $padTop;

#now start plot everything
my $refPlotted = 0;
foreach my $track (@trackOrder){
	#print STDERR "Plotting $track, current y position = $current_track_position\n";
	next if $track=~/alignment/i;
	next if $skipTracks{$track};
	my $glyph = $trackConfigs->{$track}->{'glyph'};
	if ($track =~ /REF/i){
		if ($refPlotted == 0){
			$current_track_position = &plotRef($current_track_position);
			$refPlotted = 1;
		}
	}
	elsif($glyph =~ /box/i){
		$current_track_position = &plotBox($track,$current_track_position);
	}
	
	elsif($glyph=~/hist/i){
		$current_track_position = &plotHist($track,$current_track_position);
	}
	elsif($glyph=~/vLine/i){
		$current_track_position = &plot_vLine($track,$current_track_position);
	}
}

my $labelPart1 = $trackConfigs->{'REF1'}->{'trackLabel'} || "";
my $labelPart2 = $trackConfigs->{'REF2'}->{'trackLabel'} || "";
if ($labelPart1 ne "" && $labelPart2 ne ""){
	my $title = $labelPart1."--".$labelPart2;
	&drawTitle($img,$title);
}

my $outfile = $opt{'o'};
#$img->moveTo(1,$iheight-1);
#my $string = $trackConfigs->{'REF1'}->{'gffFilter'}.", ".$trackConfigs->{'REF2'}->{'gffFilter'};
#$img->string($string);
open (IM,">$outfile") or die "Can't open $outfile\n";
print IM $img->png;
print STDERR $errors if $errors ne "";
print STDERR "DONE\n" if $opt{'v'};
#foreach my $track (keys %{$trackData}){
#	print $track."\n";
#	foreach my $k (keys %{$trackData->{$track}}){
#		print "\t$k\n";
#	}
#	print "\t\t".join(":",keys %{$trackData->{$track}->{'G2Tmaps'}})."\n";
#	my $g2tmap=$trackData->{$track}->{'G2Tmaps'}->{'g2t'};
#	my @sorted = sort{$a<=>$b} (keys %{$g2tmap});
#	
#	
#}




#########################################################
# Start Subroutines                                     #
#########################################################


sub plotRef {
	my $currTrackPos = shift;
	my $ref1Label = $trackConfigs->{'REF1'}->{'trackLabel'} || "";
	my $ref2Label = $trackConfigs->{'REF2'}->{'trackLabel'} || "";
	#print "start=$currTrackPos\n";
	#get Exon boundry positions
	my @ref1Positions = @{$trackData->{'REF1'}->{'positionArray'}};
	my @ref2Positions = @{$trackData->{'REF2'}->{'positionArray'}};
	my @ref1ExonBoundries = @{$trackData->{'REF1'}->{'exonBoundries'}};
	my @ref2ExonBoundries = @{$trackData->{'REF2'}->{'exonBoundries'}};
	my $ref1g2t = $trackData->{'REF1'}->{'G2Tmaps'}->{'g2t'};
	my $ref2g2t = $trackData->{'REF2'}->{'G2Tmaps'}->{'g2t'};
	$img->penSize($defaultPenSize,$defaultPenSize);
	$img->bgcolor('yellow');
	$img->fgcolor('black');
	my $ref1Name = $trackConfigs->{'REF1'}->{'alignmentName'};
	my $ref2Name = $trackConfigs->{'REF2'}->{'alignmentName'};
	my $ref1Len = $trackData->{'REF1'}->{'length'};
	my $ref2Len = $trackData->{'REF2'}->{'length'};
	my $arrowWidth = 5;
	
	#foreach my $r1 (@ref1Positions){
	#	foreach my $key (keys %{$r1}){
	#		print "$key=$r1->{$key}\n";
	#	}
	#	my $attribs = $r1->{'attribs'};
	#	foreach my $atkey (keys %{$attribs}){
	#		print "$atkey=$attribs->{$atkey}->[1]\n";
	#	}
	#}
	
	
	
	#plot the reference tracks together, first REF1
	my $ref1GlyphHeight = $trackConfigs->{'REF1'}->{'glyphHeight'};
	my $ref1TrackHeight = $trackConfigs->{'REF1'}->{'trackHeight'};
	my $x1 = $padLeft+(($ref1AlignPad+1) * $xScale);
	my $y1 = $currTrackPos + $ref1TrackHeight - $ref1GlyphHeight;
	my $poly = new GD::Polygon;
	my $y2 = ($y1 + (($ref1GlyphHeight-1) / 2));
	my $y3 = $y1 + $ref1GlyphHeight -1;
	my $x2 = $x1+(($ref1Len-1)*$xScale);
	$poly->addPt($x1,$y1);
	$poly->addPt($x2,$y1);
	$poly->addPt($x2+$arrowWidth,$y2);
	$poly->addPt($x2,$y3);
	$poly->addPt($x1,$y3);
	$img->polygon($poly);
	#print "ref1draw: $x1,$y1:$x2,$y3\n";
	
	#draw the exon boundries for ref1
	$img->fgcolor('black');
	foreach my $r1eb (@ref1ExonBoundries){
		my $ex1 = $ref1g2t->{$r1eb};
		$ex1 = $padLeft + (($ref1AlignPad+$ex1) * $xScale);
		$img->moveTo($ex1,$y1);
		$img->lineTo($ex1,$y3);
		$img->moveTo($ex1-1,$y1); # make the line more visible by making it wider
		$img->lineTo($ex1-1,$y3);
		
	}
	#print "after ref1=".($y1+$ref1GlyphHeight)."\n";
	
	#label REF1 Track
	#$img->fgcolor('black');
	#$img->fontsize('10');
	#$img->moveTo(25,$y3);
	#$img->string($ref1Label);
	#$img->fontsize('10');
	&drawTrackLabel($y3,$ref1Label,$defaultFontSize) if $ref1Label ne "";
	$img->fontsize($defaultFontSize);
	
	
	#now plot the alignment lines
	my $alignHeight = $trackConfigs->{'ALIGNMENT'}->{'trackHeight'};
	$y1 = $y3+1;
	$y2 = $y1 + $alignHeight/6;
	$y3 = $y2 + $alignHeight*2/3;
	my $y4 = ($y3 + $alignHeight/6)-1;
	#my $alignHeight = $refHeight*2;
	#$y2  = $y1 + $alignHeight-1;

	foreach my $k (sort {$a<=>$b} keys %{$alignMatrix}){
		if ($alignMatrix->{$k}->{'conserved'} == 1){
			$img->fgcolor('black');
		}
		else{
			$img->fgcolor('gray');
		}
		my $ax1 = $padLeft+(($k+$ref1AlignPad)*$xScale);
		my $ax2 = $padLeft+(($ref2AlignPad + $alignMatrix->{$k}->{'pos'})*$xScale);
		#print "k=$k, plotting $ax1,$y1 to $ax1,$y2; $ax2,$y3 to $ax2,$y4\n";
		$img->moveTo($ax1,$y1);
		$img->lineTo($ax1,$y2);
		$img->lineTo($ax2,$y3);
		$img->lineTo($ax2,$y4);
		
	}
	
	##draw the thick horizontal lines
	#$img->penSize(3,3);
	#$img->moveTo($padLeft+1-10,$y2-1);
	#$img->lineTo($iwidth-$padRight+10,$y2-1);
	#$img->moveTo($padLeft+1-10,$y3+1);
	#$img->lineTo($iwidth-$padRight+10,$y3+1);
	#$img->penSize($defaultPenSize,$defaultPenSize);
	
	#print "after align=".($y4+1)."\n";
	#now plot the REF2 glyph
	my $ref2GlyphHeight = $trackConfigs->{'REF2'}->{'glyphHeight'};
	my $ref2TrackHeight = $trackConfigs->{'REF2'}->{'trackHeight'};
	$poly = "";
	$x1 = $padLeft+(($ref2AlignPad +1) * $xScale);
	$y1 = $y4+1;
	$poly = new GD::Polygon;
	$y2 = ($y1 + (($ref2GlyphHeight-1) / 2));
	$y3 = $y1 + $ref2GlyphHeight -1;
	$x2 = $x1+(($ref2Len-1)*$xScale);
	$poly->addPt($x1,$y1);
	$poly->addPt($x2,$y1);
	$poly->addPt($x2+$arrowWidth,$y2);
	$poly->addPt($x2,$y3);
	$poly->addPt($x1,$y3);
	$img->polygon($poly);
	
	$img->fgcolor('black');
	foreach my $r2eb (@ref2ExonBoundries){
		my $ex1 = $ref2g2t->{$r2eb};
		$ex1 = $padLeft + (($ref2AlignPad+$ex1) * $xScale);
		$img->moveTo($ex1,$y1);
		$img->lineTo($ex1,$y3);
		$img->moveTo($ex1-1,$y1);
		$img->lineTo($ex1-1,$y3);
	}
	
	#label REF2 Track
	&drawTrackLabel($y3,$ref2Label,$defaultFontSize) if $ref2Label ne "";
	$img->fontsize($defaultFontSize);
	
	
	$currTrackPos += $ref1TrackHeight + $ref2TrackHeight + $alignHeight;
	#print "after all $currTrackPos\n";
	return $currTrackPos
}
		

sub plotHist {
	my $track = shift;
	my $currTrackPos = shift;
	
	my $trackHeight = $trackConfigs->{$track}->{'trackHeight'};
	my $alignPad = $trackConfigs->{$track}->{'reference'} eq 'REF1' ? $ref1AlignPad : $ref2AlignPad;
	my $axis = ((($trackHeight-1) / 2) + $currTrackPos);
	
	#draw the track label
	my $trackLabel=$trackConfigs->{$track}->{'trackLabel'} || "";
	if ($trackLabel ne ""){	
		my @labelLines = split("::",$trackLabel);
		my $labelPos = $currTrackPos+($trackHeight/2)-((@labelLines-1)*($defaultFontSize/2));
		&drawTrackLabel($labelPos,$trackLabel,$defaultFontSize);
	}
	$img->fontsize($defaultFontSize);
	
	#get variables and settings
	my @tData = @{$trackData->{$track}->{'positionArray'}};
	
	my $heightKey = $trackConfigs->{$track}->{'histHeightKey'};
	$img->penSize($defaultPenSize,$defaultPenSize);
	my $glyphHeight = $trackConfigs->{$track}->{'glyphHeight'} || $defaultGlyphHeight;
	my $refTrack = $trackConfigs->{$track}->{'reference'};
	my $colorKey = $trackConfigs->{$track}->{'histColorKey'} || "";
	my $g2t = $trackData->{$refTrack}->{'G2Tmaps'}->{'g2t'};
	my $plotHeight = $glyphHeight / 2;
	my $heightMax = $trackConfigs->{$track}->{'heightMax'} || -1 ;
	my $heightMin = $trackConfigs->{$track}->{'heightMin'} || 0;
	
	if (@tData != 0){
		my @heightVals;
		foreach my $line (@tData) {
			my $height;
			if ($heightKey=~/:/){
				my ($key1,$key2) = split(":",$heightKey);
				$height = $line->{$key1}->{$key2};
			}
			else{
				$height = $line->{$heightKey};
			}
			push (@heightVals,abs($height)) if $height != 0;
		}
		my @ordered = sort {$a<=>$b} @heightVals;
		#print STDERR "track=$track\n";
		my ($vmin,$vmax,$vmedian,$vmean,$vstdev) = &getStats(\@heightVals);
		#print STDERR "vmin,vmax,vmedian,vmean,vstdev=$vmin,$vmax,$vmedian,$vmean,$vstdev\n";
		my $defaultValueMax = $vmax;
		$defaultValueMax = &calcTickVals($defaultValueMax);
		if ($heightMax == -1){
			 $heightMax = $defaultValueMax;
		}
		my $heightScale = $plotHeight / $heightMax;
		
		#print STDERR "hm, track=".$trackConfigs->{$track}->{'heightMax'}."; $track\n";
		#print STDERR "hmax,hmin,hscale,gheight=$heightMax,$heightMin,$heightScale,$plotHeight\n";
		
		foreach my $line (sort {$a->{'start'}<=>$b->{'start'}} @tData) {
			my $pos = $line->{'start'};
			
			if ($trackConfigs->{$track}->{'mapRef'} eq 'genome'){
				if ($g2t->{$pos}) {
					$pos = $g2t->{$pos};
				}
				else{
					next;
				}
			}
		
			#print "keys=".join(":",(keys %{$line}))."\n";
			my $height;
			#print "hk=".$heightKey."\n";
			
			if ($heightKey=~/:/){
				my ($key1,$key2) = split(":",$heightKey);
				
				$height = $line->{$key1}->{$key2};
			}
			else{
				$height = $line->{$heightKey};
			}
			
			my $colorVal="";
			if ($colorKey ne "" && $colorKey=~/:/){
				
				my ($key1,$key2) = split(":",$colorKey);
				$colorVal = $color{$line->{$key1}->{$key2}};
				#print join(":",keys %{$line->{$key1}})."\n";
			}
			elsif($colorKey ne ""){
				$colorVal = $color{$line->{$colorKey}};
			}
			else{
				$colorVal = 'black';
			}
			#print "color=$colorVal, height=$height\n";
			
			my $strand = $line->{'strand'};
			if ($height > $heightMax) {
				$height = $heightMax;
			} elsif ($height < $heightMin) {
				$height = $heightMin;
			}
			#my $x = (($start_pos - $chromTable{$species1}->{'start'}) * $xScale);
			#my $x = (($start_pos - $chromTable{$species1}->{'start'}) * $xScale) + $tickLength;
			
			
			my $x = $padLeft+(($alignPad+$pos)*$xScale);
			my $y;
			if ( $strand eq "." || $strand == 1) {
				
				$y = ($axis - ($height * $heightScale));
				
			} else {
				$y = ($axis + (abs($height) * $heightScale));
			}
			$img->bgcolor($colorVal);
			$img->fgcolor($colorVal);
			$img->moveTo($x,$axis);
			$img->lineTo($x,$y);
		}
	}
	
	#Draw the axis last so it will overwrite small histogram heights and appear black
	$img->penSize($defaultPenSize,$defaultPenSize);
	$img->bgcolor('black');
	$img->fgcolor('black');
	my $oldFontsize = $img->fontsize();
	$img->fontsize(16);
	
	# Draw x-axis
	$img->moveTo($padLeft,$axis);
	$img->lineTo($iwidth-$padRight+1,$axis);
	# Draw y-axis
	$img->moveTo($iwidth-$padRight+1,$axis-$plotHeight);
	$img->lineTo($iwidth-$padRight+1,($axis+$plotHeight));
	# Top tick
	$img->moveTo($iwidth-$padRight+1,($axis-$plotHeight));
	$img->lineTo(($iwidth + $tickLength-$padRight+1),($axis - $plotHeight));
	$img->moveTo(($iwidth + $tickLength-$padRight+4),($axis - $plotHeight+6));
	$img->string($heightMax);
	## Middle tick
	$img->moveTo($iwidth-$padRight+1,$axis);
	$img->lineTo(($iwidth + $tickLength-$padRight+1),$axis);
	# Bottom tick
	$img->moveTo($iwidth-$padRight+1,($axis+$plotHeight));
	$img->lineTo(($iwidth + $tickLength-$padRight+1),($axis + $plotHeight));
	$img->moveTo(($iwidth + $tickLength-$padRight+4),($axis + $plotHeight + 6));
	$img->string($heightMax);
	
	$img->fontsize($oldFontsize);
	$currTrackPos += $trackHeight;
	return $currTrackPos;
}




	
sub plotBox{
	my $track = shift;
	my $currTrackPos = shift;
	#print STDERR "start y pos = $currTrackPos\n";
	my $glyphHeight = $trackConfigs->{$track}->{'glyphHeight'};
	my $trackHeight = $trackConfigs->{$track}->{'trackHeight'};
	my $refTrack = $trackConfigs->{$track}->{'reference'};
	my $refStrand = $trackData->{$refTrack}->{'positionArray'}->[0]->{'strand'};
	my $refAlignPad = $refTrack =~ /REF1/i ? $ref1AlignPad : $ref2AlignPad;
	my $exons = $trackData->{$refTrack}->{'positionArray'};
	#print STDERR "track=$track, gh=$glyphHeight, th=$trackHeight\n";
	if ($trackConfigs->{$track}->{'color'}){
		$img->bgcolor($trackConfigs->{$track}->{'color'});
	}
	else {
		$img->bgcolor('blue');
	}
	$img->fgcolor('black');
	
	
	#draw the track label
	my $trackLabel=$trackConfigs->{$track}->{'trackLabel'} || "";
	#my $labelHeight = $currTrackPos+($trackHeight*2/3);
	if ($trackLabel ne ""){
		my @labelLines = split("::",$trackLabel);
		my $labelPos = $currTrackPos+($trackHeight/2)-((@labelLines-1)*($defaultFontSize/2));
		&drawTrackLabel($labelPos,$trackLabel,$defaultFontSize);
	}
	$img->fontsize($defaultFontSize);
	
	
	
	#Genomic features need to be translated to transcript coordinates.  If a genomic feature
	#spans an exon, it will need a flare.
	
	if ($trackConfigs->{$track}->{'mapRef'} eq "genome"){
		
		my @genomePositions = @{$trackData->{$track}->{'positionArray'}};
		foreach my $gp (@genomePositions){
			my ($leftFlare,$rightFlare) = (0,0);
	
			#translate genomic coords into transcript coords, we will need them later		
			my $g2t = $trackData->{$refTrack}->{'G2Tmaps'}->{'g2t'};
			my $boxGstart = $gp->{'start'};
			my $boxGend = $gp->{'end'};
			my ($boxTstart,$boxTend,$drawStart,$drawEnd);
			
			foreach my $exon (@{$exons}){
				my $drawFlag = 0;
				my $exonStart = $exon->{'start'};
				my $exonEnd = $exon->{'end'};
				#print "estart,eend,bgstart,bgend=$exonStart,$exonEnd,$boxGstart,$boxGend\n";
				if ($exonStart<=$boxGstart && $exonEnd>=$boxGend){
					$drawFlag = 1;
				}
				elsif($exonStart<=$boxGstart && $exonEnd>$boxGstart){
					$drawFlag = 1;
					$boxGend=$exonEnd;
					if ($refStrand eq "+"){
						$rightFlare = 1;
						#print "right, estart,eend,bgstart,bgend=$exonStart,$exonEnd,$boxGstart,$boxGend\n"
					}
					else{
						$leftFlare = 1;
						#print "left, estart,eend,bgstart,bgend=$exonStart,$exonEnd,$boxGstart,$boxGend\n"
					}
					
				}
				elsif($exonStart<$boxGend && $exonEnd>=$boxGend){
					$drawFlag = 1;
					$boxGstart=$exonStart;
					if ($refStrand eq "+"){
						$leftFlare = 1;
						#print "left, estart,eend,bgstart,bgend=$exonStart,$exonEnd,$boxGstart,$boxGend\n"
					}
					else{
						$rightFlare = 1;
						#print "right, estart,eend,bgstart,bgend=$exonStart,$exonEnd,$boxGstart,$boxGend\n"
					}
				}
				
				
				if ($drawFlag == 1){
					#print "rawstart=$g2t->{$boxGstart}, rawend=$g2t->{$boxGend}\n";
					my ($drawStart,$drawEnd);
					if ($g2t->{$boxGstart} < $g2t->{$boxGend}){
						
						$drawStart = (($g2t->{$boxGstart})+$refAlignPad)*$xScale;
						$drawEnd = (($g2t->{$boxGend})+$refAlignPad)*$xScale;		
					}
					else{
						$drawEnd = (($g2t->{$boxGstart})+$refAlignPad)*$xScale;
						$drawStart = (($g2t->{$boxGend})+$refAlignPad)*$xScale;
					}
					
					my $boxStrand = "";
					if ($trackConfigs->{$track}->{'glyph'} eq "strand_box"){
						my $strandField = $trackConfigs->{$track}->{'strandField'};
						my $featureStrand;
						if ($strandField =~/attribs/){
							my ($field1,$field2) = split(":",$strandField);
							$featureStrand = $gp->{$field1}->{$field2};
							
						}
						else{
							$featureStrand = $gp->{$strandField};
						}
						
						if (($refStrand eq "+" && $featureStrand eq "+") ||
							($refStrand eq "-" && $featureStrand eq "-")){
							$boxStrand = "top";
						}
						elsif (($refStrand eq "+" && $featureStrand eq "-") ||
							($refStrand eq "-" && $featureStrand eq "+")){
							$boxStrand = "bottom";
						}
		
					}
					
					#print "currTrackPos,drawStart,drawEnd,leftFlare,rightFlare,track=$currTrackPos,$drawStart,$drawEnd,$leftFlare,$rightFlare,$track;\n";
					&drawBox($currTrackPos,$drawStart,$drawEnd,$leftFlare,$rightFlare,$track,$boxStrand)
				}
			}
		}
	}
		
	
	
	#If the feature aligns to the transcript, it can be mapped directly.  If it aligns to a protein, the
	#coords must first be translated into transcript coords.  They do not need to be associated with an exon flare.
	else{
		my ($leftFlare,$rightFlare) = (0,0);
		my @posArray = @{$trackData->{$track}->{'positionArray'}};
		if ($trackConfigs->{$track}->{'mapRef'} eq "protein"){
			#print "translating\n";
			@posArray = @{&translate(\@posArray)};
		}
		foreach my $pa (@posArray){
			my $drawStart = ($pa->{'start'}+$refAlignPad)*$xScale;
			my $drawEnd = ($pa->{'end'}+$refAlignPad)*$xScale;
			
		
			my $boxStrand="";
			
			if ($trackConfigs->{$track}->{'glyph'} eq "strand_box"){
				my $strandField = $trackConfigs->{$track}->{'strandField'};
				my $featureStrand;
				if ($strandField =~/attribs/){
					my ($field1,$field2) = split(":",$strandField);
					my $strandSymb = $pa->{$field1}->{$field2};
					$boxStrand = $strandSymb eq "+" ? "top" : "bottom";
				}
				else{
					my $strandSymb = $pa->{$strandField};
					$boxStrand = $strandSymb eq "+" ? "top" : "bottom";
				}
			
			}
			
		

			&drawBox($currTrackPos,$drawStart,$drawEnd,$leftFlare,$rightFlare,$track,$boxStrand)
		}
		
	}
	
	if ($trackConfigs->{$track}->{'glyph'} eq "strand_box"){
		#Draw the axis last so it will overwrite small histogram heights and appear black
		$img->penSize($defaultPenSize,$defaultPenSize);
		$img->bgcolor('black');
		$img->fgcolor('black');
		
		my $axis = $currTrackPos + ($trackHeight/2);
		
		# Draw x-axis
		$img->moveTo($padLeft,$axis);
		$img->lineTo($iwidth-$padRight+1,$axis);
		# Draw y-axis
		#print STDERR "axis=$axis, gh=$glyphHeight,atop=".($axis-$glyphHeight)."\n";
		$img->moveTo($iwidth-$padRight+1,$axis-$glyphHeight/2-1);
		$img->lineTo($iwidth-$padRight+1,($axis+$glyphHeight/2+1));
		
	}
	
	#print STDERR "end CurrYpos=".($currTrackPos+$trackHeight)."\n";
	$currTrackPos += $trackHeight;
	return $currTrackPos;
	
}


sub plot_vLine{
	my $track = shift;
	my $currTrackPos = shift;
	
	my $refTrack = $trackConfigs->{$track}->{'reference'};
	my $refAlignPad = $refTrack =~ /REF1/i ? $ref1AlignPad : $ref2AlignPad;
	my $trackHeight = $trackConfigs->{$track}->{'trackHeight'};
	my $glyphHeight = $trackConfigs->{$track}->{'glyphHeight'};
	my $glyphWeight = $trackConfigs->{$track}->{'glyphWeight'} || 1;
	my $glyphPos = $trackConfigs->{$track}->{'glyphPosition'} || "middle";
	my $tickWidth = 3;
	my $labelOffset = 25;
	my $newFontSize = 16;
	
	if ($trackConfigs->{$track}->{'color'}){
		$img->bgcolor($trackConfigs->{$track}->{'color'});
	}
	else {
		$img->bgcolor('blue');
	}
	$img->fgcolor('black');
	
	#draw the track label
	my $trackLabel=$trackConfigs->{$track}->{'trackLabel'} || "";
	if ($trackLabel ne ""){
		my @labelLines = split("::",$trackLabel);
		my $labelPos = $currTrackPos+($trackHeight/2)-((@labelLines-1)*($defaultFontSize/2));
		#my $labelHeight = $currTrackPos+($trackHeight/2);
		&drawTrackLabel($labelPos,$trackLabel,$defaultFontSize);
	}
	
	my $saveFsize = $img->fontsize();
	$img->fontsize($newFontSize);
	
	my @drawnSites;
	foreach my $vl (@{$trackData->{$track}->{'positionArray'}}){
		my %newDrawnSite;
		
		#draw downtick
		#print STDERR "srna=$sRNA,site=$drawSite, color=$color\n";
		#$img->bgcolor($color);
		#$img->fgcolor($color);
		my $linePos = $vl->{'start'};
		if ($trackConfigs->{$track}->{'mapRef'} eq "genome"){
			my $g2t = $trackData->{$refTrack}->{'G2Tmaps'}->{'g2t'};
			if ($g2t->{$linePos}){
				$linePos = $g2t->{$linePos};
			}
			else{
				die "Genome position $linePos doesn't exist on the transcript for vLine track $track\n";
			}
		}
		my $tickX = $padLeft + ($linePos+$refAlignPad)*$xScale;
		
		#if there is a tick mark less than the width of a tick away, the tick will need to be bumped so it can be seen
		foreach my $ds (@drawnSites){
			my $dtx = $ds->{'tickX'};
			if (abs($linePos-$dtx) <= 1 && abs($linePos-$dtx) > 0){
				$tickX+=$tickWidth;
			}
		}
		
		
		my $tickY1;
		if ($glyphPos =~ /low/i){
			$tickY1 = $currTrackPos + $trackHeight - $glyphHeight;
		}
		if ($glyphPos =~ /middle/i){
			$tickY1 = $currTrackPos + (($trackHeight - $glyphHeight)/2);
		}
		if ($glyphPos =~ /high/i){
			$tickY1 = $currTrackPos + 1;
		}
		my $tickY2 = $tickY1+$glyphHeight-1;
		if ($glyphWeight != 1){
			$img->penSize($glyphWeight,$glyphWeight);
		}
		
		$img->moveTo($tickX,$tickY1);
		$img->lineTo($tickX,$tickY2);
		$img->penSize($defaultPenSize,$defaultPenSize);
		
		$newDrawnSite{'tickX'} = $tickX;
		
		#draw the labels
		my $label = $vl->{'attribs'}->{'label'} || "";
		if ($label ne ""){
			my $labelPosition = $trackConfigs->{$track}->{'labelPosition'} || "middle";
			my $labelX = $tickX;
			my (@bumps,$labelPrintLen);
			my $bumpFlag = 0;
		
			$label = $nameSubs{$label} if $nameSubs{$label};
			$labelPrintLen = $newFontSize * length($label) * (.7);
			$labelX = $iwidth - $labelPrintLen - 25 if $labelX+$labelPrintLen > $iwidth - 25;  #25 is there in case the width of the text is not accurately calced
			foreach my $ds (@drawnSites){
				my $dstart = $ds->{'labelStart'};
				my $dend = $ds->{'labelEnd'};
				my $dbump = $ds->{'bump'};
				my $currentLeft = $labelX-$labelOffset;
				my $currentRight = $labelX-$labelOffset+$labelPrintLen;
			
				#check if labels overlap
				#print "cleft,cright,currname,oldleft,oldright,oldname,oldsite:  $currentRight,$currentLeft,$printName,$oldLeft,$oldRight,$dn,$ds\n";
				if ($currentLeft <= $dstart && $currentRight >= $dstart) {
					$bumpFlag = 1;
					push (@bumps,$dbump);
				}
				if ($currentLeft <= $dend && $currentRight >= $dend){
					$bumpFlag = 1;
					push (@bumps,$dbump);
				}
			}
			
			
			#print "after currname,currlen,xval:  $printName,$printLen,$labelXval\n";
			my $bump = 0;
			@bumps = sort {$a<=>$b} @bumps;
			my $priorMaxBump = pop @bumps;
			if ($bumpFlag==1){
				$bump += $newFontSize + 5 + $priorMaxBump;
			}
			
			
			
			#draw label
			my $labelY;
			if ($labelPosition eq "high"){
				$labelY = $tickY1-5-$bump;
			}
			else{
				$labelY = $tickY2+$newFontSize+4+$bump;
			}
			$img->moveTo($labelX-$labelOffset,$labelY);
			$img->string($label);
			$newDrawnSite{'labelStart'}=$labelX-$labelOffset;
			$newDrawnSite{'labelEnd'}=$labelX-$labelOffset+$labelPrintLen;
			$newDrawnSite{'bump'}=$bump;
			push (@drawnSites,\%newDrawnSite);
		}
	}
	
	$img->fontsize($defaultFontSize);
	$currTrackPos += $trackHeight;
	return $currTrackPos;
	
}




sub makeAlignMatrix{
	#my $tracksRef = shift;
	#my $settings = shift;
	my $ref1 = $trackConfigs->{'REF1'}->{'alignmentName'};
	my $ref2 = $trackConfigs->{'REF2'}->{'alignmentName'};
	my $alignFile = $trackConfigs->{'ALIGNMENT'}->{'alignSource'};
	open (AF,$alignFile) or die "Can't open $alignFile\n";
	my ($alignment,$order) = loadFasta(\*AF);
	my $ref1Count=0;
	my $ref2Count=0;
	my %matrix;
	my @tempRef = keys %{$alignment};
	my $len = length($alignment->{$tempRef[0]});
	for my $i (0..($len-1)){
		my $ref1Letter = substr($alignment->{$ref1},$i,1);
		my $ref2Letter = substr($alignment->{$ref2},$i,1);
		
		$ref1Count++ if $ref1Letter !~ /-/;
		$ref2Count++ if $ref2Letter !~ /-/;
		#print "len=$len, t1L=$taxa1Letter, t2L=$taxa2Letter, t1C=$taxa1Count, t2C=$taxa2Count\n";
		if ($ref1Letter !~ /-/ && $ref2Letter !~ /-/){
			$matrix{$ref1Count}->{'pos'}=$ref2Count;
			if ($ref1Letter eq $ref2Letter){
				$matrix{$ref1Count}->{'conserved'}=1;
			}
			else{
				$matrix{$ref1Count}->{'conserved'}=0;
			}
		}
	}
	my $refLen = $ref1Count > $ref2Count ? $ref1Count : $ref2Count;
	
	if ($opt{'v'}){
		open (AM,">>$opt{'v'}") or die "Can't open $opt{'v'} for writing\n";
		foreach my $r1c (sort {$a<=>$b} keys %matrix){
			print AM "$ref1\t$ref2\t$r1c\t$matrix{$r1c}->{'pos'}\t$matrix{$r1c}->{'conserved'}\n"
		}
	}
	
	return (\%matrix,$alignment);
	
}



#this must return a hash with at least the following:  seqid, start, end, score, strand, and attribs;
sub getData{
	my $trackConfRef = shift;
	my $passedTracks = shift;
	my (%tData);
	
	foreach my $track (@{$passedTracks}){
		my $positionData;
		#print STDERR  "Getting data for $track\n";
		next if $track=~/alignment/i;
		if ($track=~/REF/){
			my $geneLen=0;
			if ($trackConfRef->{$track}->{'mapType'} =~ /gff/i){
				my $gffFile = $trackConfRef->{$track}->{'gffSource'};
				my $gFilter = $trackConfRef->{$track}->{'gffFilter'};
				#print "first ".$gFilter.", track=$track\n";
				$positionData = &readGFF($gffFile,$gFilter,$track,$trackConfRef);
			}
			if (@{$positionData} == 0){
				print STDERR "Couldn't find any data for $track\n";
				exit;
			}
			my ($tempMaps,$highlow) = &makeGtoTmap($positionData,$track,$trackConfRef);
			
			$tData{$track}->{'G2Tmaps'} = $tempMaps;
			$tData{$track}->{'high'} = $highlow->{'high'};
			$tData{$track}->{'low'} = $highlow->{'low'};
			
			#get exon boundries
			my @exonBoundries;
			for my $r (0..(@{$positionData}-1)){
				last if @{$positionData} == 1;
				push(@exonBoundries,$positionData->[$r]->{'end'});
			}
			$tData{$track}->{'exonBoundries'} = \@exonBoundries;
								
			#print "highLow=$tData{$track}->{'low'}, $tData{$track}->{'high'}\n";
			foreach my $pd (@{$positionData}){
				$geneLen += $pd->{'end'}-$pd->{'start'}+1;
				
			}
			#print "$track GENELEN = $geneLen\n";
			$tData{$track}->{'length'} = $geneLen;
		}
		
		else{
			if ($trackConfRef->{$track}->{'mapType'} =~ /gff/i){
				my $gffFile = $trackConfRef->{$track}->{'gffSource'};
				my $gffFilter = $trackConfRef->{$track}->{'gffFilter'};
				$positionData = &readGFF($gffFile,$gffFilter,$track,$trackConfRef);
			}
			
			elsif($trackConfRef->{$track}->{'mapType'} =~/sRNAdb/i){
				my $ref = $trackConfRef->{$track}->{'reference'};
				my $cashxID = $trackConfRef->{$track}->{'cashxID'};
				my (@libs,@sizeClasses);
				if ($trackConfRef->{$track}->{'libraries'}){
					my $libCode = $trackConfRef->{$track}->{'libraries'};
					@libs = parseIntoArray($libCode);
				}
				if ($trackConfRef->{$track}->{'srnaSizeClasses'}){
					my $scCode = $trackConfRef->{$track}->{'srnaSizeClasses'};
					@sizeClasses = parseIntoArray($scCode);
				}
				$positionData = &readCashxDb($track,$ref,$cashxID,\@libs,\@sizeClasses);
				
			}
			
			elsif ($trackConfRef->{$track}->{'mapType'} =~/tab/i){
				$positionData = &readTab($track,$trackConfRef);
			}
			
		}
		
		if (@{$positionData}==0){
			if ($trackConfigs->{$track}->{'possibleNull'} && $trackConfigs->{$track}->{'possibleNull'}==1){
				print STDERR "Can't find data for $track, but I hear that's ok\n";
			}
			else{
				die "Can't find data for $track\n";
			}
		}
		
		#print "Returning ".@{$positionData}." for track $track\n";
		#if (@{$positionData} < 30){
		#	foreach my $feat (@{$positionData}){
		#		foreach my $k (keys %{$feat}){
		#			print "$k=$feat->{$k}: ";
		#		}
		#		print "\n";
		#	}
		#}
		
		
		
		$tData{$track}->{'positionArray'} = $positionData;
		#print "track=$track, count=".@{$tData{$track}->{'positionArray'}}."\n";
	}
	
	
	return \%tData;
}


sub readGFF {
	my $gFile = shift;
	my $gFilter = lc(shift);
	my $track = shift;
	my $conf = shift;
	my @retArray;
	open (GF,$gFile) or die "Can't open $gFile\n";
	while (my $line = <GF>){
		next if $line=~/#/;
		next if $line =~ /^[\n\r\s]+$/;
		chomp $line;
		#print "line=$line\n";
		my @sLine = split("\t",$line);
		
		#if there are attributes, put them into a data structure
		#some attribute types contain more than one entry (e.g. Name=A,B), which is also handled here
		#assume that attribute names will never be the same as the default column names
		
		if ($sLine[8] ne '.'){
			my %attribs;
			my @tempSplit = split(';',$sLine[8]);
			foreach my $t (@tempSplit){
				#print STDERR "t=$t\n" if $track =~ /REF1/;
				$t=~/([^=]+)=(.*)/;
				my ($aName,$aVal) = ($1,$2);
				if ($aVal=~/[,:]/){
					my @valArray = split(/[,:]/,$aVal);
					$attribs{$aName}=\@valArray;
				}
				else{
					$attribs{$aName} = $aVal;
				}
				
			}
			$sLine[8] = \%attribs;
		}
		
		my %dataHash;
		#my $checkString = "";
		for (my $i = 0; $i < 9;$i++){
			$dataHash{$gffFields[$i]}=$sLine[$i];
			#$checkString .= "$gffFields[$i]=$sLine[$i]:";
		}
		#print STDERR "check=".$checkString."\n";
		
		#filter out any lines that don't match a few criteria
		my $failCount=0;
		
		#first check to see if the line matches $gFilter
		$failCount += &filterName(\%dataHash,$gFilter,$track) if $gFilter ne "";
		
		#then make sure the reference track is a CDS line or that it matches the typefilter
		if ($trackConfigs->{$track}->{'gffTypeFilter'}){
			#print STDERR "typefilt=$trackConfigs->{$track}->{'gffTypeFilter'}";
			if ($track =~ /REF/ && $dataHash{'type'} ne  $trackConfigs->{$track}->{'gffTypeFilter'}){
				$failCount++;
			}
		}
		elsif ($track =~ /REF/ && ($dataHash{'type'} ne "CDS" && $dataHash{'type'} ne "pseudogenic_CDS")){
			$failCount++;
		}
		
		#then check if the current gff line is within the position range specifed by the ref track
		if ($track!~/REF/ && $conf->{$track}->{'mapRef'} eq 'genome' ){
			$failCount += &filterPosition(\%dataHash,$track);
		}
		
		#print "dataHash=$dataHash{'seqid'}:";
		#if ($failCount == 0){
		#	foreach my $k (keys %dataHash){
		#		print "$k=$dataHash{$k}\n";
		#	}
		#}
		
		push(@retArray,\%dataHash) if $failCount == 0;
		
	}
	
	return \@retArray;
	
	
}

sub readCashxDb{
	my $track = shift;
	my $ref = shift;
	my $cashxID = shift;
	my @libList = @{(shift)};
	my @sizeClasses = @{(shift)};
	
	my (@dbLibs,%dbLibHash);
	my $ReadCASHX1 = new ReadCASHX(conf => $cashxConfFile, species => $cashxID);
	$ReadCASHX1->query("generic_select", "*", "library_list");
	while (my $row = $ReadCASHX1->results("hash")){
		push (@dbLibs,$row->{'library_id'});
		$dbLibHash{$row->{'library_id'}} = $row->{'total_reads'};
	}
	#print join("\n",(sort {$a<=>$b} keys %dbLibHash))."\n";
	my %libHash;
	if (@libList == 0){
		%libHash = %dbLibHash;
	}
	else{
		foreach my $l (@libList){
			if ($dbLibHash{$l}){
				$libHash{$l} = $dbLibHash{$l};
			}
			else{
				$errors .= "Library $l did not exist in the CASHX database, skipping\n";
			}
			
		}
	}
	if (keys %libHash == 0) {
		die "No valid libraries selected for $ref $track\n";	
	}
	
	my %sizeClassesToKeep;
	if (@sizeClasses==0){
		for my $n (15..35){
			$sizeClassesToKeep{$n} = 1;
		}
	}
	else{
		foreach my $s (@sizeClasses){
			$sizeClassesToKeep{$s} = 1;
		}
	}
	

	my $highPos = $trackData->{$ref}->{'high'};
	my $lowPos = $trackData->{$ref}->{'low'};
	my $refSeqid = $trackData->{$ref}->{'positionArray'}->[0]->{'seqid'};
	$refSeqid =~ /(\d+)/;
	my $refChrom = $1;
	
	
	
	my $accession = $trackConfigs->{$track}->{'accession'};
	my %rawHits;
	
	#first get hits from the HitGenome table
	if ($trackConfigs->{$track}->{'dbtype'} eq "transcript"){
		
		$ReadCASHX1->query("generic_select_HitGenome", "*", "WHERE hit_accession = '$accession'");
		while (my $row = $ReadCASHX1->results("hash")){
			#dcl normalize
			if ($row->{'hit_strand'} == -1){
				$row->{'hit_start'} += 2;
			}
			$rawHits{$row->{'seq_id'}} = $row;
		}
		
		
	}
	
	else{
		#loop through each exon and see if there is a hit that is encompassed by the exon
		my @exons = @{$trackData->{$ref}->{'positionArray'}};
		foreach my $exon (@exons){
			my $eStart = $exon->{'start'};
			my $eEnd = $exon->{'end'};
			#print "estart=$eStart, eend=$eEnd\n";
			for (my $i = $eStart; $i <= $eEnd; $i++){
				#print "trying $i\n";
				$ReadCASHX1->query("generic_select_HitGenome", "*", "WHERE hit_start = '$i' AND hit_chromNum = '$refChrom'");
				while (my $row = $ReadCASHX1->results("hash")){
					if ($row->{'hit_end'} < $eEnd){
						if ($row->{'hit_strand'} == -1){
							$row->{'hit_start'} += 2;
						}
						$rawHits{$row->{'seq_id'}} = $row;
					}
				}
			}
		}
	}
	print "temp hits = ".(keys %rawHits)."\n";
	#get readcounts for each hit
	foreach my $seq_id (keys %rawHits){
		$ReadCASHX1->query("generic_select", "*", " unapproved WHERE seq_id = '$seq_id'");
		my $row = $ReadCASHX1->results("hash");
		my $sid = $row->{'sid'};
		$rawHits{$seq_id}->{'sid'} = $sid;
		foreach my $l (keys %libHash){
			$ReadCASHX1->query("generic_select", "*", " unapproved_reads WHERE sid='$sid' AND library_id = '$l'");
			my $readCount = $ReadCASHX1->results("hash");
			if ($readCount->{'reads'}){
				my $reads = $readCount->{'reads'};
				if ($normFactor > 0){
					$reads *= ($normFactor/$libHash{$l})
				}
				$rawHits{$seq_id}->{'reads'} += $reads;
				#print "adding from lib $l, $readCount->{'reads'}\n" if $sid == 5744;
			}	
		}
	}
	
	#now make sure there are not hits with 0 reads. Also, filter by size class.
	#print "temp data kesy = ".(keys %rawHits)."\n";
	my %hitData;
	foreach my $seq_id (keys %rawHits){
		#print STDERR "seq_id=$seq_id, reads = $rawHits{$seq_id}->{'reads'}\n";
		my $keepFlag = 1;
		if (!$rawHits{$seq_id}->{'reads'} || $rawHits{$seq_id}->{'reads'} == 0){
			$keepFlag = 0;
		}
		my $seqLen = length($rawHits{$seq_id}->{'hit_seq'});
		if (!$sizeClassesToKeep{$seqLen}){
			$keepFlag = 0;
		}

		if ($keepFlag == 1){
			$rawHits{$seq_id}->{'sizeClass'} = $seqLen;
			$hitData{$seq_id}=$rawHits{$seq_id};
		}
	}
	%rawHits = ();
	
	
	#print "finalhitdat=".(keys %hitData)."\n";
	
	#build each position hash and push into the return array
	my @retArray;
	foreach my $srnaDat (values %hitData){
		my %retHash = ('seqid'=>$refChrom,
					   'start' => $srnaDat->{'hit_start'},
					   'end' => $srnaDat->{'hit_end'},
					   'score' => $srnaDat->{'reads'},
					   'strand' => $srnaDat->{'hit_strand'});
		
		
		my %attrib = ('sizeClass'=>$srnaDat->{'sizeClass'});
		$retHash{'attribs'} = \%attrib;
		push (@retArray,\%retHash);
		
	}
	#print "retcount=".@retArray."\n";
	
	#foreach my $r (@retArray){
	#	print "cashxReturn=";
	#	foreach my $k (keys %{$r}){
	#		if ($k eq "attrib"){
	#			foreach $a (keys %{$r->{$k}}){
	#				print "$a=$r->{$k}->{$a}:";
	#			}
	#		}
	#		else{
	#			print "$k=$r->{$k}:";
	#		}
	#	}
	#	print "\n";
	#}
	
	return \@retArray;
	

}

sub readTab {
	my $track = shift;
	my $conf = shift;
	
	my @retArray;
	my $sourceFile = $conf->{$track}->{'source'};
	my $dataColumn = $conf->{$track}->{'dataColumn'}-1;
	my ($filterField,$filterValue);
	my $filter = $conf->{$track}->{'filter'} || "";
	if ($filter ne ""){
		($filterField,$filterValue) = split(":",$filter);
	}
	$filterField -= 1;
	my $labelField = $conf->{$track}->{'label'} || "";
	#print "source,dc,filter,filterfield,filterval=$sourceFile,$dataColumn,$filter,$filterField,$filterValue\n";
	open (TAB,$sourceFile) or die "Can't open $sourceFile\n";	
	while (my $line = <TAB>){
		next if $line=~/#/;
		next if $line =~ /^[\n\r\s]+$/;
		chomp $line;
		#print "line=$line\n";
		my @sLine = split("\t",$line);
		
		#make sure the data colums from the conf file actually exist and that they match filter
		next if !$sLine[$dataColumn];
		next if ($filter ne "" && !$sLine[$filterField]);
		next if ($filter ne "" && $sLine[$filterField] ne $filterValue);
	
		#passed the tests, load data	
		my %dataHash = ('seqid'=>$filterValue,
					   'start' => $sLine[$dataColumn],
					   'end' => $sLine[$dataColumn],
					   'score' => ".",
					   'strand' => "1");
		if (my $labelField = $conf->{$track}->{'label'}){
			$labelField -= 1;
			if (!$sLine[$labelField]){
				$errors .= "WARNING: In the datafile for $track, you specified that there should be a label but none was found\n";
			}
			$dataHash{'attribs'} = {'label'=>$sLine[$labelField]};
			
		}
		push(@retArray,\%dataHash);
		
	}
	
	#foreach my $ra (@retArray){
	#	foreach my $hk (keys %{$ra}){
	#		print $hk=$ra->{$hk}."\n";
	#	}
	#	foreach my $ak (keys %{$ra->{'attribs'}}){
	#		print "attrib $ak = $ra->{'attribs'}->{$ak}\n";
	#	}
	#
	#}
	
	return \@retArray;
	
	
}



sub makeGtoTmap {
	my @data = @{(shift)};
	my $track = shift;
	my $conf = shift;
	
	my (%G2T,%T2G,$high,$low);
	my $strand = $data[0]->{'strand'};
	my $transcriptPos = 1;
	if ($strand eq "+"){
		@data = sort {$a->{'start'}<=>$b->{'start'}} @data;
		foreach my $d (@data){
			next if ($d->{'type'} ne "CDS" && $d->{'type'} ne "pseudogenic_CDS");
			for (my $i=$d->{'start'};$i<=$d->{'end'};$i++){
				$G2T{$i}=$transcriptPos;
				$T2G{$transcriptPos} = $i;
				$transcriptPos++;
			}
		}
	}
	else{
		@data = sort {$b->{'start'}<=>$a->{'start'}} @data;
		#print "Negmakemaptrack=$track\n";
		foreach my $d (@data){
			next if ($d->{'type'} ne "CDS" && $d->{'type'} ne "pseudogenic_CDS");
			for (my $i=$d->{'end'};$i>=$d->{'start'};$i--){
				$G2T{$i}=$transcriptPos;
				$T2G{$transcriptPos} = $i;
				$transcriptPos++;
			}
		}
	}
	
	my @sorted = sort {$a<=>$b} (keys %G2T);
	
	my (%retHash1,%retHash2);
	$retHash1{'g2t'} = \%G2T;
	$retHash1{'t2g'} = \%T2G;
	$retHash2{'high'} = $sorted[@sorted-1];
	$retHash2{'low'} = $sorted[0];
	return (\%retHash1,\%retHash2)
}





#this allows data imports that contain information for more than just the features of interest
#this subroutine is responsible for allowing only those features through that are specified as the desired features

sub filterName {
	my $lineRef = shift;
	my $gFilters = shift;
	my $track = shift;
	
	$gFilters =~ tr/ //;
	my @filterPairs = split(";",$gFilters);
	#print STDERR join("::",@filterPairs)."\n";
	#exit if $track eq 'ATHDEGRADOME';
	my $rVal = 0;
	foreach my $pair (@filterPairs){
		#print "pair=$pair\n";
		my ($gField,$gName)=split(":",$pair);
		#print "ffield=$gField, fname=$gName\n" if $track eq 'ATHDEGRADOME';
		#check to see if the name given in the conf file matches
		if ($gField =~ /attribs/i){
			if ($lineRef->{'attribs'} eq '.'){
				$rVal = 1;
			}
			else{
				my $foundVal = 0;
				foreach my $attrib (values %{$lineRef->{'attribs'}}){
					if (ref($attrib) eq "ARRAY"){
						foreach my $at (@{$attrib}){
							$foundVal = 1 if $at=~/^$gName$/i;
							#print STDERR "found $a for gname=$gName\n" if $attrib=~/^$gName$/i;
						}
					}
					else{
						$foundVal = 1 if $attrib=~/^$gName$/i;
						#print STDERR "found $attrib for gname=$gName\n" if $attrib=~/^$gName$/i;
						#exit if $attrib=~/^$gName$/i;
						
					}
				}
				$rVal = 1 if $foundVal == 0;
				
			}
		}
		else{
			#print "lineref=$lineRef->{$gField}\n" if $lineRef->{$gField} =~/AT1G627/;
			if ($lineRef->{$gField}!~/$gName/i){
				$rVal = 1;
			}
			#else{print "yay, rval=$rVal\n"}
		}
	}
	#print "returning rval=$rVal\n";
	return $rVal;
	
}

sub filterPosition {
	my $lineRef = shift;
	my $track = shift;
	
	my $refTrack = $trackConfigs->{$track}->{'reference'};
	my $refHigh = $trackData->{$refTrack}->{'high'};
	my $refLow = $trackData->{$refTrack}->{'low'};
	$trackData->{$refTrack}->{'positionArray'}->[0]->{'seqid'}=~/(\d+)/;
	my $refChrom = $1;
	if (($lineRef->{'start'} < $refLow && $lineRef->{'end'}> $refLow) ||
		($lineRef->{'start'} < $refHigh && $lineRef->{'end'} > $refHigh) ||
		($lineRef->{'start'} > $refLow && $lineRef->{'end'} < $refHigh))
	{
		#print "low=$low, high=$high, tps=$tp->{'start'}, tpe=$tp->{'end'}\n";
			$lineRef->{'seqid'}=~/(\d+)/;
			my $boxChrom = $1;
			return $boxChrom == $refChrom ? 0 : 1;
	}
	else{
		return 1;
	}
}

sub translate{
	my $data = shift;
	my $dCount = @{$data};
	for my $d (0..($dCount-1)){
		my $start = $data->[$d]->{'start'};
		my $end  = $data->[$d]->{'end'}; 
		$data->[$d]->{'start'} = (($start-1)*3)+1;
		$data->[$d]->{'end'} = $end*3;
	}
	return $data;
}


sub drawBox {
	my $currentTrackY = shift;
	my $start = shift;
	my $end = shift;
	my $lFlare = shift;
	my $rFlare = shift;
	my $track = shift;
	my $boxStrand;
	if (@_ > 0){
		$boxStrand = shift;
	}
	
	my $flareHeight = 3;
	
	#print "curtrack=$currentTrackY, start=$start, end=$end, lflare=$lFlare, rflare=$rFlare;\n";
	my $flareWidth = 5;
	my $trackHeight = $trackConfigs->{$track}->{'trackHeight'};
	my $glyphHeight = $trackConfigs->{$track}->{'glyphHeight'};
	my $glyph = $trackConfigs->{$track}->{'glyph'};
	my ($yTop,$yBottom,$axisY);
	if ($glyph eq "strand_box"){
		$axisY = $currentTrackY+($trackHeight/2);
		
		#$yTop = $currentTrackY + (($trackHeight-$glyphHeight-1)/2);
		#$yBottom = $yTop + $glyphHeight;
		if ($boxStrand eq "top"){
			$yTop = $axisY - ($glyphHeight/2);
			$yBottom = $axisY - $flareHeight; #leave room for the flare at the bottom of the glyph
		}
		else{
			$yTop = $axisY + $flareHeight; #leave room for the flare at the top of the glyph
			$yBottom = $axisY + ($glyphHeight/2); 
		}
	}
	else{
		$yTop = $currentTrackY + (($trackHeight-$glyphHeight-1)/2);
		$yBottom = $yTop + $glyphHeight;
	}
	#print STDERR "ytop=$yTop, yBot=$yBottom\n";
	my (@topPlotPoints,@bottomPlotPoints);
	#print "track=$track, box ytop=$yTop, ybottom=$yBottom, gheight=$glyphHeight\n";	
	#my (%point1,%point2,%point3,%point4);
	#print "ytop,ybottom=$yTop,$yBottom\n";
	#calc positions for left flare
	#my $x1 = $padLeft + ($start*$xScale);
	#my $x2 = $padLeft + ($xScale*($start+$flareWidth-1));
	my $x1 = $padLeft + $start;
	my $x2 = $padLeft + $start+$flareWidth-1;

	if ($lFlare==1){
		my $y1 = $yTop-$flareHeight;
		my $y2 = $yBottom+$flareHeight;
		push(@topPlotPoints,{'x'=>$x1,'y'=>$y1});
		push(@topPlotPoints,{'x'=>$x2,'y'=>$yTop});
		push(@bottomPlotPoints,{'x'=>$x1,'y'=>$y2});
		push(@bottomPlotPoints,{'x'=>$x2,'y'=>$yBottom});
		#print "lflare, start=$start, end=$end, points=$x1:$y1,$x2:$yTop,$x1:$y2,$x2:$yBottom\n"
	}
	else{
		push(@topPlotPoints,{'x'=>$x1,'y'=>$yTop});
		push(@topPlotPoints,{'x'=>$x2,'y'=>$yTop});
		push(@bottomPlotPoints,{'x'=>$x1,'y'=>$yBottom});
		push(@bottomPlotPoints,{'x'=>$x2,'y'=>$yBottom});
		#print "no lflare, $start:$yTop,$start+4:$yTop,$start:$yBottom,$start+4:$yBottom\n"
	}
	
	$start += $flareWidth;
	#$x1 = $padLeft + ($start*$xScale);
	#$x2 = $padLeft + ($xScale*($end-$flareWidth));
	$x1 = $padLeft + $start;
	$x2 = $padLeft + $end-$flareWidth;
	
	#calc main part of box
	push(@topPlotPoints,{'x'=>$x1,'y'=>$yTop});
	push(@topPlotPoints,{'x'=>$x2,'y'=>$yTop});
	push(@bottomPlotPoints,{'x'=>$x1,'y'=>$yBottom});
	push(@bottomPlotPoints,{'x'=>$x2,'y'=>$yBottom});
	
	$start = $end-$flareWidth+1;
	$x1 = $padLeft + $start;
	$x2 = $padLeft + $end;
	#calc right flare
	if ($rFlare==1){
		my $y1 = $yTop-$flareHeight;
		my $y2 = $yBottom+$flareHeight;
		push(@topPlotPoints,{'x'=>$x1,'y'=>$yTop});
		push(@topPlotPoints,{'x'=>$x2,'y'=>$y1});
		push(@bottomPlotPoints,{'x'=>$x1,'y'=>$yBottom});
		push(@bottomPlotPoints,{'x'=>$x2,'y'=>$y2});
		#print "rflare, start=$start, end=$end, points=$x1:$yTop,$x2:$y1,$x1:$yBottom,$x2:$y2\n"
	}
	else{
		push(@topPlotPoints,{'x'=>$x1,'y'=>$yTop});
		push(@topPlotPoints,{'x'=>$x2,'y'=>$yTop});
		push(@bottomPlotPoints,{'x'=>$x1,'y'=>$yBottom});
		push(@bottomPlotPoints,{'x'=>$x2,'y'=>$yBottom});
	}
	
	@bottomPlotPoints = reverse(@bottomPlotPoints);
	
	#print "\ntopPoints\n";
	#foreach my $tp (@topPlotPoints){
	#	print "$tp->{'x'}:$tp->{'y'}\n";
	#}
	#print "\nbottomPoints\n";
	#foreach my $tp (@bottomPlotPoints){
	#	print "$tp->{'x'}:$tp->{'y'}\n";
	#}
	
	my $poly = new GD::Polygon;
	
	foreach my $pair(@topPlotPoints){
		#print "toppair: x=$pair->{'x'}, y=$pair->{'y'}, axis=$axis\n";
		$poly->addPt($pair->{'x'},$pair->{'y'});
	
	}
	foreach my $pair(@bottomPlotPoints){
		#print "bottompair: x=$pair->{'x'}, y=$pair->{'y'}\n";
		$poly->addPt($pair->{'x'},$pair->{'y'});
	}
	$img->polygon($poly);

}

sub drawTitle{
	my $img = shift;
	my $titleName = shift;
	$titleName =~ s/\/.*\///;
	$img->fgcolor('black');
	$img->bgcolor('black');
	$img->fontsize(16);
	my $xPos = ($iwidth/2)-70;
	$img->moveTo($xPos,$padTop/2);
	$img->string($titleName);
	$img->fontsize(20);
}

sub drawTrackLabel {
	my $yPos = shift;
	my $labelText = shift;
	my $fontSize = shift;
	
	my @labels = split("::",$labelText);
	
	#print STDERR "ypos,trackheight,labels=$yPos,$trackHeight,@labels\n";
	#my $labelY = $yPos + ($trackHeight/2) - 12*@labels;  #go to the middle and move up
	$img->fgcolor('black');
	$img->fontsize($fontSize);
	foreach my $layer (0..(@labels-1)){
		$yPos += $layer*($fontSize+2);
		my $printThis = $labels[$layer];
		$img->moveTo(25,$yPos);
		$img->string($printThis);
	}
	
}


sub loadFasta {
	my $fh = shift;
	my %returnHash;
	my $header="";
	my $seq="";
	my @order;
	while (my $line = <$fh>){
		next if $line =~ /^#/;
		next if $line =~ /^[\n\r]+$/;
		chomp $line;
		if ($line=~/>(\S+)/){
			my $newHeader = $1;
			push (@order,$newHeader);
			if ($seq ne ""){
				$returnHash{$header} = $seq;
				$seq = "";
			}
			$header = $newHeader;
		}
		elsif (eof($fh)){
			$returnHash{$header}=$seq.$line;
		}
		else {
			$seq .= $line;
		}
	}
	return (\%returnHash,\@order);
}


sub calcTickVals{
	my $peakHeight = shift;
	if ($peakHeight <= 2){return (2);}	
	elsif ($peakHeight <= 5){return (5);}
	elsif ($peakHeight <= 10){return (10);}
	elsif ($peakHeight <= 20){return (20);}
	elsif ($peakHeight <= 30){return (30);}
	elsif ($peakHeight <= 40){return (40);}
	elsif ($peakHeight <= 50){return (50);}
	elsif ($peakHeight <= 60){return (60);}
	elsif ($peakHeight <= 70){return (70);}
	elsif ($peakHeight <= 80){return (80);}
	elsif ($peakHeight <= 90){return (90);}
	elsif ($peakHeight <= 100){return (100);}
	elsif ($peakHeight <= 200){return (200);}
	elsif ($peakHeight <= 400){return (400);}
	elsif ($peakHeight <= 800){return (800);}
	elsif ($peakHeight <= 1500){return (1500);}
	elsif ($peakHeight <= 2000){return (2000);}
	elsif ($peakHeight <= 5000){return (5000);}
	elsif ($peakHeight <= 10000){return (10000);}
	elsif ($peakHeight <= 20000){return (20000);}
	elsif ($peakHeight <= 30000){return (30000);}
	else{return(40000,1000);}
}


sub round {
	my $num = shift;
	if ($num =~ /\d+\.(\d)/) {
		if ($1 >= 5) {
			$num = ceil($num);
		} else {
			$num = floor($num);
		}
	}
	return $num;
}

sub parseIntoArray {
	my $input = shift;
	my @temp_list;
	my @final_list;

	# put each semicolon separated entry in an array
	if ($input =~ /\,/) {
		@temp_list = split (/\,/,$input);
	} else {
		push(@temp_list,$input);
	}

	# expand range entries
	foreach my $temp_element (@temp_list){
		if ($temp_element =~ /-/) {
			my ($low_num, $high_num) = split (/\-/, $temp_element);
			if(! ($low_num < $high_num)){
				croak("Error: invalid input range\n");
			}
			for my $this_num ($low_num..$high_num){
				push(@final_list,$this_num);
			}
		} else {
			push(@final_list,$temp_element);
		}
	}
	return @final_list;
}


#returns, in order: min,max,median,mean,stdev
sub getStats {
	my $arr_ref = $_[0];
	
	my @values = sort {$a<=>$b} @{$arr_ref};
	my ($min,$max,$median,$mean,$stdev);
	
	#calc min and max
	$min = $values[0];
	$max = $values[@values-1];
	
	#calc median
	if (@values == 0){
		$median = 0;
	}
	elsif (@values == 1){
		$median = $values[0];
	}
	else{
		my $mid = @values / 2;
		if (@values % 2 == 0){
			$median = ($values[($mid-1)] + $values[($mid)]) / 2;
		}
		else{
			$median = $values[($mid-.5)]; 
		}
	}
	
	#calc avg and stdev
	my $n = 0;
	my $sumsq = 0;
	my $sum = 0;
	foreach (@$arr_ref) {
		next unless (defined($_) && ($_ !~ /^$/));
		$n++;
		$sumsq += $_ * $_;
		$sum += $_;
	}
	if (@values != 0){
		$mean = $sum / @values;	
	}
	else{
		$mean = "NA";	
	}
	
	if (@$arr_ref == 1){
		$stdev = 0;
	}
	else{
		my $var = (($n * $sumsq) - ($sum * $sum))/($n * ($n - 1));
		$stdev = ($var < 0) ? 0 : sqrt($var);
	}

	return ($min,$max,$median,$mean,$stdev);
}



sub var_check {
	my $errors = "";
	
	if ($opt{'C'}) {
		$alignment = $opt{'C'};
	} else {
		$errors .=  "You have not specified a conf file (-C).\n";
	}
	
	if ($errors ne ""){
		print $errors."\n";
		&var_error()
	}
	
} #end var_check


sub var_error {
	
	
	my $scriptName = $0;
	$scriptName =~ s/\/?.*\///;
	
	print STDERR "$scriptName <-C Conf file> <-o output filename> [-v]\n";
	print STDERR <<PRINTTHIS;

This script will plot an alignment between two genes and their associated data tracks.

Usage:

Mandatory:
-C  The configuration file
-o  The output file

Optional:
-v  filename.  Verbose output.  Prints additional status lines to STDOUT.  Also prints the
	alignment matrix to the file specified.  If file already exists, it will be appended.


PRINTTHIS
	exit 0;
}


