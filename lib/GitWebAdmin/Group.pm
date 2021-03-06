#
#  Copyright (C) 2009,2010 Astaro GmbH & Co. KG  www.astaro.com
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
#  Author: Frank Lichtenheld <flichtenheld@astaro.com> 07.07.2009
#
##############################################################################
package GitWebAdmin::Group;
use base 'GitWebAdmin';

use strict;
use warnings;

sub find_group {
  my $c = shift;

  my $db = $c->param('db');
  my $gid = $c->param('id');
  my $group = $db->resultset('Groups')->find($gid);

  return $group;
}

sub list {
  my $c = shift;

  my $db = $c->param('db');
  my @groups = $db->resultset('Groups')->search(
    {}, { order_by => 'gid' });
  die "404 No Groups found\n" unless @groups;

  return $c->json_output(\@groups) if $c->want_json;
  return $c->tt_process({ groups => \@groups });
}

sub create_form {
  my $c = shift;

  die "403 Not authorized" unless $c->is_admin;

  return $c->tt_process();
}

sub create {
  my $c = shift;

  $c->param('id', $c->query->param('gid'));
  my $group = $c->find_group;
  die "403 Not authorized\n" unless $c->is_admin;
  die "409 Group already exists\n" if $group;
  die "409 Group ID missing\n" unless $c->param('id');

  my %opts = (
    gid => $c->query->param('gid'),
    name => $c->query->param('name') || '',
    );

  my $members = $c->get_obj_list('Users', 'members', { key => 'users_uid_key' });
  my ($w_repos, $r_repos) =
    $c->get_writable_readable('Repos', 'writable', 'readable');

  my $rs = $c->param('db')->resultset('Groups');
  my $new_group = $rs->create({ %opts });
  $new_group->set_users($members);
  $new_group->set_w_repos($w_repos);
  $new_group->set_r_repos($r_repos);

  return $c->redirect($c->url('group/' . $new_group->gid));
}


sub delete {
  my $c = shift;

  my $group = $c->find_group;
  die "403 Not authorized\n" unless $c->is_admin;
  die "404 Group not found\n" unless $group;

  $group->delete;

  return $c->tt_process({ group => $group });
}

sub do {
  my $c = shift;

  if( my $d = $c->rest_dispatch({ delete => 'delete', put => 'create' })){
    return $c->$d();
  }
  my $group = $c->find_group;
  die "404 Group not found\n" unless $group;

  if( $ENV{REQUEST_METHOD} eq 'POST' ){
    die "403 Not authorized\n"
      unless $c->is_admin;

    $group->name($c->query->param('name'));
    $group->descr($c->query->param('description'));
    my $members = $c->get_obj_list('Users', 'members', { key => 'users_uid_key' });
    my ($w_repos, $r_repos) =
      $c->get_writable_readable('Repos', 'writable', 'readable');

    $group->set_users($members);
    $group->set_w_repos($w_repos);
    $group->set_r_repos($r_repos);

    $group->update->discard_changes;
  }

  return $c->json_output($group) if $c->want_json;
  return $c->tt_process({ group => $group });
}

1;
