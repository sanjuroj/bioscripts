#!/bin/sh
# -o /home/mcb/jogdeos/softwareAndscripts/scripts/qsubSample/qOut
# -e /home/mcb/jogdeos/softwareAndscripts/scripts/qsubSample/qErr
#$ -o ../qOut
#$ -e ../qErr
#$ -cwd
#$ -N blastout
#$ -S /bin/sh
#

/local/cluster/bin/blastall -i $1 -o $2 -d ../blastDB/TAIR8_chromosomes.nfa -p blastn -m 8 -e 1e-10
