#
#  Copyright (C) 2016 Sophos Ltd. www.sophos.com
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
#  Author: Frank Lichtenheld <frank.lichtenheld@sophos.com> 06.09.2016
#
##############################################################################
package GitWebAdmin::PushLogs;
use base 'GitWebAdmin';

use strict;
use warnings;

use File::Spec::Functions qw(rel2abs);

sub setup {
  my $c = shift;

  $c->run_modes([qw(edit_form)]);
}

sub find_repo {
  my $c = shift;

  my $db = $c->param('db');
  my $repo_id = $c->param('repo');
  if( defined $repo_id ){
    my $repo = $db->resultset('Repos')->find($repo_id)
      or die "409 Invalid Repository";
    return $repo;
  }

  return;
}

sub find_branches {
  my $c = shift;

  my $db = $c->param('db');
  my $branch = $db->resultset('Branches');
  my $repo_id = $c->param('repo');
  $branch = $branch->search({ rid => $repo_id },
                            { order_by => 'branch' });

  return $branch;
}

sub find_log {
  my $c = shift;

  my $db = $c->param('db');
  my $logs = $db->resultset('LogsPush');
  my $repo_id = $c->param('repo');
  my $name = $c->param('branch_name');
  unless( $name =~ m@^refs/@ ){
    $name = 'refs/heads/'.$name;
  }

  my $log = $logs->search({ rid => $repo_id, 'ref' => $name },
                          { order_by => 'date DESC',
                            join => 'uid' });
  return $log;
}

sub list {
  my $c = shift;

  my $repo = $c->find_repo;
  my $branches = $c->find_branches;
  die "404 No branches found\n" unless $branches->count;

  return $c->json_output([ $branches->all ]) if $c->want_json;
  return $c->tt_process({ branches => $branches, repo => $repo });
}


sub do {
  my $c = shift;

  my $repo = $c->find_repo;
  my $log = $c->find_log;
  die "404 No log entries found\n" unless $log->count;

  return $c->json_output([ $log->all ]) if $c->want_json;
  return $c->tt_process({ ref => $c->param('branch_name'),
                          log => $log, repo => $repo });
}


1;
