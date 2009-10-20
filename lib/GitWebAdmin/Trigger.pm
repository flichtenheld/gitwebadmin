#
#  Copyright (C) 2009 Astaro AG  www.astaro.com
#  All rights reserved.
#
#  Author: Frank Lichtenheld <flichtenheld@astaro.com> 20.10.2009
#
##############################################################################
package GitWebAdmin::Trigger;
use base 'GitWebAdmin';

use strict;
use warnings;

sub find_trigger {
  my $c = shift;

  my $db = $c->param('db');
  my $id = $c->param('id');
  my $trigger;
  if( $id =~ /^\d+$/ ){
    $trigger = $db->resultset('ExternalTriggers')->find($id);
  }else{
    $trigger = $db->resultset('ExternalTriggers')->find($id,
      { key => "external_triggers_name_key" });
  }

  return $trigger;
}

sub list {
  my $c = shift;

  my $db = $c->param('db');
  my @triggers = $db->resultset('ExternalTriggers')->search(
    {}, { order_by => 'name' });
  die "404 No Triggers found\n" unless @triggers;

  return $c->json_output(\@triggers) if $c->want_json;
  return $c->tt_process({ triggers => \@triggers });
}

sub create_form {
  my $c = shift;

  die "403 Not authorized" unless $c->is_admin;

  return $c->tt_process();
}

sub create {
  my $c = shift;

  $c->param('id', $c->query->param('name'));
  my $trigger = $c->find_trigger;
  die "409 Trigger already exists\n" if $trigger;
  die "403 Not authorized\n" unless $c->is_admin;

  my %opts = (
    name => $c->query->param('name') || '',
    method => $c->query->param('method') || '',
    uri => $c->query->param('uri') || '',
    );

  my $repos = $c->get_obj_list('Repos', 'repos');

  my $rs = $c->param('db')->resultset('ExternalTriggers');
  my $new_trigger = $rs->create({ %opts });
  $new_trigger->set_repos($repos);

  return $c->redirect($c->url('trigger/' . $new_trigger->name));
}

sub delete {
  my $c = shift;

  my $trigger = $c->find_trigger;
  die "404 Trigger not found\n" unless $trigger;
  die "403 Not authorized\n" unless $c->is_admin;

  $trigger->delete;

  return $c->tt_process({ trigger => $trigger });
}

sub do {
  my $c = shift;

  if( my $d = $c->rest_dispatch({ delete => 'delete', put => 'create' })){
    return $c->$d();
  }
  my $trigger = $c->find_trigger;
  die "404 Trigger not found\n" unless $trigger;

  if( $ENV{REQUEST_METHOD} eq 'POST' ){
    die "403 Not authorized\n"
      unless $c->is_admin;

    $trigger->name($c->query->param('name'));
    $trigger->method($c->query->param('method'));
    $trigger->uri($c->query->param('uri'));

    my $repos = $c->get_obj_list('Repos', 'repos');
    $trigger->set_repos($repos);

    $trigger->update->discard_changes;
  }

  return $c->json_output($trigger) if $c->want_json;
  return $c->tt_process({ trigger => $trigger });
}

1;
