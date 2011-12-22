#
#  Copyright (C) 2009 Astaro GmbH & Co. KG  www.astaro.com
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#  Author: Kai Baesler <kbaesler@astaro.com> 14.04.2009
#
##############################################################################
package Dutil;
use strict;
use warnings;

use Carp;
use Fcntl qw( :flock );
use POSIX qw( setsid strftime );
use IO::File;

our $timeout = 5;   # timeout for locks
our $silent  = 1;   # don't cry when you fail to get the lock
our $sizelimit = 2 * 1024 * 1024; # 2 megabytes
our $timestamp = "%Y-%m-%d %H:%M:%S"; # how to format the time in output

sub singularize {
    my $filename = shift;

    # open the file in read+write mode. this succeeds even when the file
    # is locked, because locking is merely advisory.
    # we use a global filehandle here, because we want this handle to
    # be there for the whole lifetime of the process.
    open LOCK_FH, '+<', $filename or croak "can't open $filename: $!";

    local $@;
    eval {
        # try to acquire the lock (flock is a blocking call) and let the OS
        # send us an interrupting signal when we can't get it within $timeout
        # seconds. We know that we got the lock when $@ is clean afterwards
        local $SIG{ALRM} = sub { die "Timeout\n" };
        alarm $timeout;
        flock(LOCK_FH, LOCK_EX);
        autoflush LOCK_FH 1;
        alarm 0;
    };
    if ($@) {
        if ($@=~/Timeout/) {
            # flock interrupted by SIGALRM, so we know another process has the
            # lock and we can safely exit, but in debugging mode ($silent=0),
            # we prefer to get a message that there's another process
            exit 0 if $silent;
            croak "another process holds the lock on $filename";
        }

        # something's gone wrong acquiring the lock
        croak "Error: $@";
    }
}

sub daemonize {
    # see perlipc(3pm) for rationale of this
    open STDIN,  '</dev/null'   or croak "can't re-open STDIN: $!";
    open STDOUT, '>/dev/null'   or croak "can't re-open STDOUT: $!";

    my $pid = fork;
    defined($pid)               or croak "can't fork: $!";
    exit if $pid;
    setsid                      or croak "can't start new session: $!";

    print LOCK_FH "$$\n"        or warn  "can't write pid file: $!";
    open STDERR, '>&STDOUT'     or croak "can't dup STDOUT: $!";
}

sub redirect {
    my $filename = shift;
    # prevent excessive groth of unattended logfiles
    if ( -f $filename and (-s $filename > $sizelimit) ) {
        rename $filename, "$filename.bak";
    }
    # make sure that warn() and die() go somewhere
    open STDOUT, '>>', $filename or croak "can't re-open STDOUT: $!";
    open STDERR, '>&STDOUT'      or croak "can't re-open STDOUT: $!";

    # we want to be able to see the messages in realtime
    autoflush STDOUT 1;
    autoflush STDERR 1;
}

sub install_handlers {

    # add timestamps to Perls warn() and die(), to make the logfiles
    # even more useful.

    $SIG{__WARN__} = sub {
        my $msg = shift;
        my $ts = strftime($timestamp, localtime);
        warn "$ts $0\[$$\]: $msg\n";
    };

    $SIG{__DIE__} = sub {
        my $msg = shift;
        my $ts = strftime($timestamp, localtime);
        die "$ts $0\[$$\]: $msg\n";
    };
}

sub log {
    my $msg = shift;

    my $ts = strftime($timestamp, localtime);
    print "$ts $0\[$$\]: $msg\n";
}

1;
__END__

=head1 NAME

Dutil - Daemonization utility functions

=head1 SYNOPSIS

  use Dutil;

  Dutil::singularize( '/path/to/lockfile' );
  Dutil::daemonize;
  Dutil::redirect( '/logs/go/here' );   # STDOUT/STDERR go here
  Dutil::install_handlers;

  Dutil::log( "some message" );


=head1 DESCRIPTION

This module provides functionality that is usually needed in the context of
lightweight system daemons. You want to make sure that a given process is
running only once on your system, and that output is handled gracefully,
even when Perl throws a warning or dies.

=head2 Functions

=over 4

=item Dutil::singularize( $filename )

Make sure that there's only one process running at a time by putting an
exclusive lock on the file given by $filename. The next process that
tries to singularize the same file will terminate and thus make sure that
only a single process is running. This is safe, because the system will
remove the lock, once the process that first required it, stops.

You can customize the behaviour by setting the I<$Dutil::timeout> to a
timeout (in seconds), after which the second process will exit if it can't
acquire the lock. The Default is 5 seconds.

If you set the I<$Dutil::silent> variable to 0 you can make the process
print out a warning if it fails to acquire the lock, but usually you'll want
this behaviour to be a bit less obtrusive, so the default here is 1 (which
means be silent, no message). If you ever suffered from a process filling
your logfiles with these stupid messages, you'll appreciate the silent method.


=item Dutil::daemonize

Send the current process to the background, closing filehandles and
starting a new process group as needed. See perlipc(3pm) for more.

=item Dutil::redirect( $filename )

Redirect the STDOUT and STDERR filehandles to the file given by $filename,
and move away any old file if it exceeds a given size. Both STDOUT and STDERR
are set to autoflush so that you can actually see in realtime what's happening.
Keep this in mind when you're doing lot's of output, because this will slow
down your output-performance on these two filehandles (better open and use
your own handles).

This redirection is mostly done to fetch Perls error messages from warn()
and die().

If you're thinking of implementing a long-running daemon, consider calling
this function once a day to make sure that you log does not grow to much.

=item Dutil::install_handlers

Set a new handler for warn() and die(), which adds a short timestamp to the
beginning of the error message. This is very handy and makes sure that you're
not bothering with last years errors again.
The process name and the process id are also included.

The timestamp format defaults to "%Y-%m-%d %H:%M:%S", but you can change
this to any other strftime compatible format string by setting the
I<$Dutil::timestamp> variable.

=item Dutil::log( $message )

Put a timestamped message in the same log that STDOUT goes to. Uses the same
process id and process name information to format the message.

=back

=head2 EXPORT

nothing is exported, you have to call all functions by their full name.

=head1 AUTHOR

Kai Bäsler, E<lt>kbaesler@astaro.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Astaro GmbH & Co. KG  www.astaro.com

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
