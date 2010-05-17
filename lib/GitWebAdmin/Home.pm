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
