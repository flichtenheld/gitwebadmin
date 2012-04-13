#
#  Copyright (C) 2012 Astaro GmbH & Co. KG  www.astaro.com
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
#  Author: Frank Lichtenheld <Frank.Lichtenheld@sophos.com> 11.04.2012
#
##############################################################################
package GitWebAdmin::Mirror;

use base qw(GitWebAdmin);

use strict;
use warnings;

use DateTime;


sub list {
  my $c = shift;

  my $db = $c->param('db');
  my @mirrors = $db->resultset('Mirrors')->search(
    { 'repo.deleted' => 0 },
    {
      join => 'repo',
      order_by => [ $c->query->param('sort_by') || (), 'repo.name' ],
    });
  die "404 No Mirror Repositories found\n" unless @mirrors;

  return $c->json_output(\@mirrors) if $c->want_json;
  return $c->tt_process({ mirrors => \@mirrors,
                          now => time });
}


1;
