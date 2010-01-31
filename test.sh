#! /bin/bash

# A crude set of tests of the Log Monitoring Solution by manipulating a test
# log file and seeing what happens.
#
# http://www.analysisandsolutions.com/software/log_monitoring_solution/
# http://github.com/convissor/log_monitoring_solution
#
# Author: Daniel Convissor <danielc@analysisandsolutions.com>
# License: http://www.analysisandsolutions.com/software/license.htm Simple Public License
# Copyright: The Analysis and Solutions Company, 2010


script=log_monitoring_solution.pl
expected=0
username=`whoami`

function kill_script {
    echo "sleeping for 5"
    sleep 5

    pid=`ps -C $script -o pid=`
    echo "killing $pid"
    kill $pid

    echo "sleeping for 2"
    sleep 2

    rm -f t.txt
    rm -f r.txt
}

function put_expect {
    let expected++

    if [ $2 ] ; then
        file=$2
    else
        file=t.txt
    fi

    echo $1
    echo "$expected = $1" >> $file
}

function put_ignore {
    if [ $2 ] ; then
        file=$2
    else
        file=t.txt
    fi

    echo $1
    echo $1 >> $file
}


echo "-----"
rm -f t.txt
rm -f r.txt
echo "calling $script, but t.txt doesn't exist yet"
./$script $username &
echo "sleeping for 2"
sleep 2

put_expect "PHP Fatal error: non-ex -- something into t.txt"
echo "sleeping for 5"
sleep 5

echo "move t.txt to r.txt"
mv t.txt r.txt
put_expect "PHP Fatal error: non-ex -- something into r.txt" r.txt
echo "sleeping for 5"
sleep 5

put_expect "PHP Fatal error: non-ex -- something into new t.txt"

kill_script


echo "-----"
cat /dev/null > t.txt

echo "calling $script, while t.txt exists"
./$script $username &
echo "sleeping for 2"
sleep 2

put_expect "PHP Fatal error: ex -- something into t.txt"
put_ignore "Eep Oop Ork Ah Ah: ex -- SHOULD NOT MATCH into t.txt"
echo "sleeping for 5"
sleep 5

echo "move t.txt to r.txt"
mv t.txt r.txt
put_expect "PHP Fatal error: ex -- something into r.txt" r.txt
echo "sleeping for 5"
sleep 5

put_expect "PHP Fatal error: ex -- something into new t.txt"
put_expect "PHP Fatal error: ex -- testing 2x throttle"
put_ignore "PHP Fatal error: ex -- testing 2x throttle"
echo "sleeping for 5"
sleep 5
put_expect "PHP Fatal error: ex -- testing 2x throttle"

kill_script


echo "-----"
cat /dev/null > t.txt

echo "calling $script, for move then delete"
./$script $username &
echo "sleeping for 2"
sleep 2

put_expect "PHP Fatal error: ex-move -- something into t.txt that will then be moved"

echo "move t.txt to r.txt"
mv t.txt r.txt
echo "sleeping for 5"
sleep 5

echo "removing r.txt"
rm r.txt
echo "sleeping for 5"
sleep 5

put_expect "PHP Fatal error: ex-move -- first thing into putting something into new t.txt after removing r.txt"

kill_script


echo "-----"
put_ignore "PHP Fatal error: ex-prefill -- NOT SHOW 1 into t.txt"
put_ignore "PHP Fatal error: ex-prefill -- NOT SHOW 2 into t.txt"
put_ignore "PHP Fatal error: ex-prefill -- NOT SHOW 3 into t.txt"
put_ignore "PHP Fatal error: ex-prefill -- NOT SHOW 4 into t.txt"
put_ignore "PHP Fatal error: ex-prefill -- NOT SHOW 5 into t.txt"
echo "sleeping for 2"
sleep 2

echo "calling $script, for move then delete"
./$script $username &
echo "sleeping for 2"
sleep 2

put_expect "PHP Fatal error: ex-prefill -- show now into t.txt"

kill_script


echo "-----"
cat /dev/null > t.txt

echo "calling $script, to truncate"
./$script $username &
echo "sleeping for 2"
sleep 2

put_expect "PHP Fatal error: ex-truncate -- some long message pre-truncate into t.txt"
echo "sleeping for 5"
sleep 5

echo "truncating..."
cat /dev/null > t.txt

put_expect "PHP Fatal error: ex-truncate -- something post-truncate into t.txt"

kill_script


echo "-----"
echo "There should be $expected emails in box."
