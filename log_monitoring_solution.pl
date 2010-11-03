#! /usr/bin/perl -w
use strict;

# Watches the log file of your chosing in real time for any matches against
# the regular expression you provide and notifies you of them via email.
#
# Keeps track of duplicate messages and sends the resulting count of them at
# intervals, rather than clogging inboxes with one email per error.
#
# Gracefully handles situations where the log file doesn't exist yet or
# gets rotated.
#
# Comes pre-configured to monitor fatal and parse errors generated by
# PHP scripts.
#
#
# This script and log_monitoring_solution_runner.pl must be in the same
# directory.  We suggest /usr/local/bin.
#
# This script is started and managed by log_monitoring_solution_runner.sh.
# That shell script must be executed by a cron job on a regular basis.
# See log_monitoring_solution_crontab.txt for an example.
#
# All three files contain settings that may need adjusting.  Please examine
# each file and make the changes necessary for your environment.
#
# For more information, see the INSTALL.txt file in this directory or the
# Manual at the package home page, below.
#
#
# http://www.analysisandsolutions.com/software/log_monitoring_solution/
# http://github.com/convissor/log_monitoring_solution
#
# Author: Daniel Convissor <danielc@analysisandsolutions.com>
# License: http://www.analysisandsolutions.com/software/license.htm Simple Public License
# Copyright: The Analysis and Solutions Company, 2010


# ===== SETTINGS =====
my $php_log = '/var/log/php5/php_errors.log';

# Case-insensitive regular expression to check each line against.
my $regex = 'PHP (Fatal|Parse) error: (.*)';

# The id of the subpattern in $regex that contains the specific error
# message.  Used for tracking duplicate messages.
my $details_subpattern_id = 2;

my $mail_subject = 'PHP FATAL ERROR';
my $mail_to = 'root@localhost';
my $mail_from = 'root@localhost';

# Leave this alone unless you know what you're doing.
my @mail_cmd = ('/usr/sbin/sendmail', '-f', $mail_from, $mail_to);

# The number of seconds to spend sleeping between reads.
my $interval = 60;

# The number of minutes until renotification of duplicate error messages.
my $throttle = 60;
# ====================


# Obtain required packages.
use Digest::MD5 qw(md5_hex);
use Sys::Hostname;


# Declare global variables.
my $curpos = 0;
my $fh_php_log;
my $host = hostname();
my $initial_inode = 0;
my $md5 = '';
my $seek = 1;  # Start from end of file.
my %sent = ();


#
# Get down to business...
#

open_file();
if ($seek) {
	# Jump to the end of the file.
	seek($fh_php_log, -s $php_log, 0);
}

for (;;) {
	if (! -e $php_log
		|| $initial_inode != (stat($php_log))[1]
		|| $curpos > (stat($php_log))[7] )
	{
		# The initial file has been removed, renamed or truncated.
		open_file();
	}

	read_file();

	sleep($interval);
	seek($fh_php_log, $curpos, 0);
}


#
# Function declarations.
#

# Opens $php_log.
# If the initial file was moved, any remaining data extracted from it.
# If the file doesn't exist yet, sleep for $interval, then check again.
# Returns 1 when the file exists.
sub open_file {
	if (defined($fh_php_log)) {
		# A log file was already opened.  It probably got moved.
		if ((stat($fh_php_log))[7]) {
			# It still has content, which we shall read
			# before trying to access the new file.
			read_file();
		}
		close($fh_php_log);
		reset 'fh';
		$curpos = 0;
	}

	for (;;) {
		if (-e $php_log) {
			open($fh_php_log, $php_log) or die send_error(
				"log_monitoring_solution.pl couldn't open $php_log: $!", 0, 0);
			$initial_inode = (stat($fh_php_log))[1];
			return 1;
		}
		# File doesn't exist yet.

		# Once it does, get all data in it, don't seek() the end of the file.
		$seek = 0;

		# Wait a while before checking for the file again.
		sleep($interval);
	}
}

# Reads lines from $fh_php_log, looking for matches against $regex.
# Creates an md5 of the $details_subpattern_id'th returned by $regex and uses that as
#   a key for %sent.
# If the md5 doesn't exist, sends an email right away.
# If the md5 exists and the prior email was sent more than $throttle minutes
#   ago, sends another email now saying how many times the error happend
#   since the last email.
sub read_file {
	no strict 'refs';  # To enable details_subpattern_id reference.
	
	for ($curpos = tell($fh_php_log); $_ = <$fh_php_log>; $curpos = tell($fh_php_log)) {
		if ( m/$regex/i ) {
			$md5 = md5_hex $$details_subpattern_id;

			if (exists $sent{$md5}) {
				if ((time() - $sent{$md5}{'time'}) > ($throttle * 60)) {
					send_error($_, $sent{$md5}{'count'}, $sent{$md5}{'time'});
					$sent{$md5}{'time'} = time();
					$sent{$md5}{'count'} = 0;
				}
				$sent{$md5}{'count'}++;
			} else {
				$sent{$md5}{'time'} = time();
				$sent{$md5}{'count'} = 1;
				send_error($_, $sent{$md5}{'count'}, $sent{$md5}{'time'});
			}
		}
	}
}

# Composes and submits the email messages.
sub send_error {
	my ($body, $count, $time) = @_;

	open(my $fh_mail, '|-', @mail_cmd) or die "Can't open @mail_cmd: $!";
	print $fh_mail "To: $mail_to\n";
	print $fh_mail "Subject: $mail_subject\n";
	print $fh_mail "Content-type: text/plain\n\n";

	print $fh_mail "Host: $host\n";
	print $fh_mail "Error Log: $php_log\n\n";
	if ($count > 1) {
		my $mins = int((time() - $time) / 60);
		print $fh_mail "The following error happened $count times in the "
				. "past $mins minutes.\n\n";
	}
	print $fh_mail $body;

	close($fh_mail) or die "Problem closing $fh_mail: $!";
}
