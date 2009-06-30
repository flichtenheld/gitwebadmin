package GitWebAdmin::User;
use base 'GitWebAdmin';

use strict;
use warnings;

sub setup {
  my $c = shift;

  $c->run_modes([qw(change_key delete_key set_groups)]);
}

sub find_user {
  my $c = shift;

  my $db = $c->param('db');
  my $uid = $c->param('id');
  my $user = $db->resultset('Users')->find($uid);

  return $user;
}

sub list {
  my $c = shift;

  my $db = $c->param('db');
  my @users = $db->resultset('Users')->search(
    {}, { order_by => 'uid' });
  die "404 No Users found\n" unless @users;

  return $c->tt_process({ users => \@users });
}

sub do {
  my $c = shift;

  my $user = $c->find_user;
  die "404 User not found\n" unless $user;

  return $c->tt_process({ user => $user });
}

sub change_key {
  my $c = shift;

  my $user = $c->find_user;
  die "404 User not found\n" unless $user;
  # users can only change their own keys
  die "403 Not authorized\n" unless $user->uid eq $c->param('user');

  my $key = $c->query->param('pubkey');
  $user->key($key);
  $user->update();

  return $c->tt_process({ user => $user });
}

sub set_groups {
  my $c = shift;

  my $user = $c->find_user;
  die "404 User not found\n" unless $user;
  # only admins can set group memberships
  die "403 Not authorized\n" unless $c->is_admin;

  my @groups = $c->query->param('groups');
  my %groups = map { $_ => 1 } @groups;
  delete $groups{none};

  my $rs = $c->param('db')->resultset('Groups');
  @groups = map { $rs->find($_) } keys %groups;

  $user->set_groups(\@groups);

  return $c->redirect($c->url('user/'.$user->uid));
}

1;
