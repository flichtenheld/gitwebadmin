#
#  Copyright (C) 2009 Astaro AG  www.astaro.com
#  All rights reserved.
#
#  Author: Frank Lichtenheld <flichtenheld@astaro.com> 07.07.2009
#
##############################################################################
package GitWebAdmin::Home;
use base 'GitWebAdmin';

use strict;
use warnings;

sub start {
  my $c = shift;

  my $db = $c->param('db');
  my $repos = $db->resultset('ActiveRepos')->search(
    {}, { order_by => $c->query->param('sort_by') || 'name' });
  my $groups = $db->resultset('Groups');
  my $users = $db->resultset('Users');

  return $c->json_output({ repos =>  [ map { $_->name } $repos->all  ],
                           groups => [ map { $_->gid }  $groups->all ],
                           users  => [ map { $_->uid }  $users->all  ],
                         }) if $c->want_json;
  return $c->tt_process({ repos => $repos,
                          groups => $groups,
                          users => $users });
}

1;
