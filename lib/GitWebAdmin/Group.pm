package GitWebAdmin::Group;
use base 'GitWebAdmin';

use strict;
use warnings;

sub list {
  my $c = shift;

  my $db = $c->param('db');
  my @groups = $db->resultset('Groups')->search(
    {}, { order_by => 'gid' });
  die "404 No Groups found\n" unless @groups;

  return $c->tt_process({ groups => \@groups });
}

sub do {
  my $c = shift;

  my $db = $c->param('db');
  my $gid = $c->param('id');
  my $group = $db->resultset('Groups')->find($gid);
  die "404 Group not found\n" unless $group;

  return $c->tt_process({ group => $group });
}

1;
