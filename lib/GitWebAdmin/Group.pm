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

  return $c->tt_process({ groups => \@groups });
}

sub delete {
  my $c = shift;

  my $group = $c->find_group;
  die "404 Group not found\n" unless $group;
  die "403 Not authorized\n" unless $c->is_admin;

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

  return $c->tt_process({ group => $group });
}

1;
