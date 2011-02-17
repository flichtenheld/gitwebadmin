#!/usr/bin/env perl
#
#  Copyright (C) 2010,2011 Astaro GmbH & Co. KG  www.astaro.com
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
#  Author: Kai Bäsler <kbaesler@astaro.com>
#
##############################################################################
use strict;
use warnings;

use File::Basename;
use POSIX qw( strftime );

use IO::Socket;
use Socket qw( :DEFAULT :crlf );

our $LOGFILE='/var/git/mirror.log';
our $GITURL ='git://git.intranet.astaro.de/';
our $CHECKIN='http://mantis.intranet.astaro.de/plugin.php?page=Source/checkin';

sub logmsg (;$);

$0 = basename($0);
$SIG{ __WARN__ } = sub { logmsg "@_"; warn "@_"; };
$SIG{ __DIE__  } = sub { logmsg "@_"; die  "@_"; };

my $zeroref='0000000000000000000000000000000000000000';


if (@ARGV==1) {
    send_mirror_request($ARGV[0]);
}
elsif (@ARGV==4) {
    my ($repo, $oldref, $newref, $branch) = @ARGV;
    send_mirror_request( $repo );
    (my $name = $repo ) =~ s!\.git!!;
    my $data = join("+", $oldref, $newref, $branch);
    (my $branchname = $branch) =~ s!^/?refs/heads/!!;

    if ($oldref eq $newref) {
        # only possible if $oldref and $newref are '0000...'
        # remote mirror repository, no commit IDs available
        # full run
        my $full_git_url = $GITURL . $repo;
        logmsg "import full: $full_git_url";
        logmsg `curl -K ~/.curlrc.full -d repo_url=$full_git_url`;
    }
    elsif ($newref eq $zeroref) {
        # a branch has been deleted
        logmsg "branch '$branchname' has been deleted from $name (skip)";
    }
    else {
        my $hint = ($oldref eq $zeroref) ? 'new branch' : '';
        # a new branch has been created
        logmsg "checkin $hint$branchname in $name";
        logmsg `curl -K ~/.curlrc.checkin -d "repo_name=$name" -d data="$data"`;
    }

}
else {
    print "Usage: $0 <REPONAME> [ <OLDREF> <NEWREF> <BRANCHNAME> ]\n";
}
exit 0;




sub send_mirror_request {
    my $reponame = shift || die "missing parameter 'repo name'";
    my $c = IO::Socket::INET->new(PeerAddr => 'localhost:8023')
            or die "can't connect: $!";
    $c->print( $GITURL . $reponame . $CRLF );
}

sub logmsg (;$) {
    my $now = strftime("%Y-%m-%d %H:%M:%S:", localtime);
    if (open my $logfh, '>>', $LOGFILE) {
        printf $logfh "%s %s[%d]: %s\n", $now, $0, $$, @_;
    }
}
