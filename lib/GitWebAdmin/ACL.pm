#
#  Copyright (C) 2010 Astaro AG  www.astaro.com
#  All rights reserved.
#
#  Author: Frank Lichtenheld <flichtenheld@astaro.com> 11.01.2010
#
##############################################################################
package GitWebAdmin::ACL;

use base 'Exporter';

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

1;
