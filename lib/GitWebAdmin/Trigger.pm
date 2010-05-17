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
