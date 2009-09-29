#
#  Copyright (C) 2009 Astaro AG  www.astaro.com
#  All rights reserved.
#
#  Author: Frank Lichtenheld <flichtenheld@astaro.com> 07.07.2009
#
##############################################################################
package GitWebAdmin::User;
use base 'GitWebAdmin';

use strict;
use warnings;

use GitWebAdmin::Utils;

sub setup {
  my $c = shift;

  $c->run_modes([qw(add_key change_key delete_key display_key set_groups set_subscriptions)]);
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

  return $c->json_output(\@users) if $c->want_json;
  return $c->tt_process({ users => \@users });
}

sub do {
  my $c = shift;

  my $user = $c->find_user;
  die "404 User not found\n" unless $user;

  return $c->json_output($user) if $c->want_json;
  return $c->tt_process({ user => $user });
}

sub get_key {
  my $c = shift;

  my $key;
  if( my $key_file = $c->query->upload('pubkey_file') ){
    $key = <$key_file>;
    close $key_file;
  }elsif( $c->query->param('pubkey') ){
    $key = $c->query->param('pubkey');
  }
  chomp($key);
  $key =~ s/^\s+//;
  $key =~ s/\s+$//;

  return if length($key) > 1000;
  return if $key =~ m/\n/;

  return $key;
}

sub find_key {
  my $c = shift;

  my $user = $c->find_user;
  die "404 User not found\n" unless $user;
  # users can only see or change their own keys
  die "403 Not authorized\n" unless $user->uid eq $c->param('user');

  my $id = $c->param('kid');
  die "400 No key id given\n" unless $id;

  return $user->find_related('keys', $id);
}

my $key_tmpl = "GitWebAdmin/User/display_key.tmpl";
sub add_key {
  my $c = shift;

  my $user = $c->find_user;
  die "404 User not found\n" unless $user;
  # users can only change their own keys
  die "403 Not authorized\n" unless $user->uid eq $c->param('user');

  my $key = $c->get_key;
  die "400 No key given or key invalid\n" unless $key;

  my ($bits, $fpr, $type) = GitWebAdmin::Utils::check_key($key);
  die "400 Key invalid\n" unless $fpr;

  my $name = $c->query->param('name');
  die "400 No name given\n" unless $name;

  my $key_obj = $user->create_related('keys',
                                      { key => $key, name => $name,
                                        fingerprint => $fpr, bits => $bits,
                                        type => (defined($type) ? lc($type) : undef)
                                      });

  return $c->redirect($c->url('user/'.$key_obj->uid->uid.'/key/'.$key_obj->id));
}

sub delete_key {
  my $c = shift;

  my $key = $c->find_key;
  die "404 Key not found\n" unless $key;

  $key->delete;
  return $c->redirect($c->url('user/'.$key->uid->uid, '', 'pubkeys'));
}

sub display_key {
  my $c = shift;

  my $key = $c->find_key;
  die "404 Key not found\n" unless $key;

  return $c->json_output($key) if $c->want_json;
  return $c->tt_process($key_tmpl,
                        { action => 'show', key => $key });
}

sub change_key {
  my $c = shift;

  if( my $d = $c->rest_dispatch({ delete => 'delete_key', put => 'add_key' })){
    return $c->$d();
  }

  my $key = $c->find_key;
  die "404 Key not found\n" unless $key;

  $key->name($c->query->param('name'));
  my $action = 'nochange';
  if( $key->is_changed ){
    $key->update->discard_changes;
    $action = 'change';
  }

  return $c->tt_process($key_tmpl,
                        { action => $action, key => $key });
}

sub set_groups {
  my $c = shift;

  my $user = $c->find_user;
  die "404 User not found\n" unless $user;
  # only admins can set group memberships
  die "403 Not authorized\n" unless $c->is_admin;

  my $groups = $c->get_obj_list('Groups', 'groups');

  $user->set_groups($groups);

  return $c->redirect($c->url('user/'.$user->uid));
}

sub set_subscriptions {
  my $c = shift;

  my $user = $c->find_user;
  die "404 User not found\n" unless $user;
  die "403 Not authorized\n"
    unless $c->is_admin or $user->uid eq $c->param('user');

  my $subscriptions = $c->get_obj_list('Repos', 'subscriptions');
  $subscriptions = [grep { $c->can_subscribe($_) } @$subscriptions];
  $user->set_subscribed_repos($subscriptions);

  return $c->redirect($c->url('user/'.$user->uid));
}

1;
