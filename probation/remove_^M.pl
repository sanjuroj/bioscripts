#!/bin/bash


if [ "$1" = "" ] ; then
        /bin/echo "Usage: $0 Filename"
        exit 1
fi


/usr/bin/perl -pi -e 's/\r\n/\n/g;' $1
/usr/bin/perl -pi -e 's/\r/\n/g;' $1
