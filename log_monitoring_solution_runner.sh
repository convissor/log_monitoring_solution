#! /bin/bash

# Starts the log_monitoring_solution.pl if it isn't already running.
#
# This script and log_monitoring_solution.pl must be in the same
# directory.  We suggest /usr/local/bin.
#
# This must be executed by a cron job on a regular basis.
# See log_monitoring_solution_crontab.txt for an example.
#
# http://www.analysisandsolutions.com/software/log_monitoring_solution/
# http://github.com/convissor/log_monitoring_solution
#
# Author: Daniel Convissor <danielc@analysisandsolutions.com>
# License: http://www.analysisandsolutions.com/software/license.htm Simple Public License
# Copyright: The Analysis and Solutions Company, 2010


dir=`dirname $BASH_SOURCE`
cmd="$dir/log_monitoring_solution.pl"
result=`ps aux | grep $cmd | grep -v grep`

if [ "$result" = "" ] ; then
    $cmd &
fi
