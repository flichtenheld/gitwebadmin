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

sub create_form {
  my $c = shift;

  die "403 Not authorized" unless $c->is_admin;

  return $c->tt_process();
}

sub create {
  my $c = shift;

  $c->param('id', $c->query->param('gid'));
  my $group = $c->find_group;
  die "409 Group already exists\n" if $group;
  die "403 Not authorized\n" unless $c->is_admin;

  my %opts = (
    gid => $c->query->param('gid') || '',
    name => $c->query->param('name') || '',
    );

  my $members = $c->get_obj_list('Users', 'members');
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
