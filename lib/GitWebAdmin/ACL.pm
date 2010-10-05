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
#  Author: Frank Lichtenheld <flichtenheld@astaro.com> 11.01.2010
#
##############################################################################
package GitWebAdmin::ACL;

use base qw(Exporter GitWebAdmin);

our @EXPORT_OK = qw(filter_acl check_acl);

use strict;
use warnings;

use Data::Dumper;

sub filter_acl {
  my ($db, $params) = @_;

  my @acls = $db->resultset('PushAcl')->search({}, { order_by => 'priority' });
  my @result;
  foreach (@acls){
    push @result, $_ if $_->check_acl($params);
  }
  return \@result;
}

sub check_acl {
  my ($db, $params) = @_;

  my %debug = %$params;
  $debug{user} = $params->{user}->uid if $params->{user};
  $debug{repo} = $params->{repo}->name if $params->{repo};
#  warn "D: check_acl:\n".Data::Dumper->Dump([\%debug], [qw(*input_params)]);

  my @acls = $db->resultset('PushAcl')->search({}, { order_by => 'priority' });
  foreach (@acls){
#    warn "D: rule ".$_->acl2str;
    my $result = $_->check_acl($params);
#    warn "D: matched!\n" if $result;
    return $result if $result;
  }
  return 'allow';
}

sub list {
  my $c = shift;

  my $db = $c->param('db');
  my @acls = $db->resultset('PushAcl')->search(
    {}, {
      order_by => [ $c->query->param('sort_by') || (), 'priority' ],
    });
  die "404 No ACLs found\n" unless @acls;

  return $c->json_output(\@acls) if $c->want_json;
  return $c->tt_process({ acls => \@acls });
}


1;
