#! /bin/bash

# Starts the log_monitoring_solution.pl if it isn't already running.
#
#
# WARNING:  Paths and email address may need adjusting.  PLEASE READ...
#
# Output caused by errors in the Perl script itself have to be handled.
# This script offers three examples.  Example 1 is used by default --
# sending output to /var/log/log_monitoring_solution.log.  Please see
# the examples at the bottom of this file and pick and tweak the option
# that best suits your environment.
#
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
    # Pick ONE of the following options, or create your own.
    # Comment out the others.
    # Naturally, adjust the paths and email address as needed.

    # Example 1:  Redirect Perl output to a log file.
    $cmd &>> /var/log/log_monitoring_solution.log &

    # Example 2:  Redirect Perl output to a log file and send an email.
    # $cmd 2>&1 | /usr/bin/tee -a /var/log/log_monitoring_solution.log \
    #     | /usr/bin/mail -s 'Log Monitoring Solution Error' root@localhost &

    # Example 3:  Send Perl output into the abyss.
    # $cmd &>> /dev/null &
fi
