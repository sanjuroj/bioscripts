#!usr/bin/perl;
#  need to accommodate a header
open (FILE,"outputClean");
#@lines = <FILE>;
#print (@lines);
#print ("\n\n");
@counts;
$previous=0;

while(<FILE>) {
	($scaf,$gene,$start,$stop, $dir, $num) = (split(/\t/,$_))[0,2,3,4,6,8];
    @temp = split(/[_;]/,$num);
    $num = $temp[3]+0;
    @temp = split(/_/,$scaf);
    $scaf = $temp[1];
    #print "prev=",$previous,", num=",$num,"\n";
    
    if($previous != $num){
        $counts[$scaf-1]++;
    }
    $previous = $num;
}

#print "\nnum=",$num,",scaf=",$scaf;
$i=@counts;
for ($n = 0;$n<$i;$n++){
    print "scaff",$n+1,"=",$counts[$n],"\n";
}

#print @counts,"\n";
#print "i=",$i;




