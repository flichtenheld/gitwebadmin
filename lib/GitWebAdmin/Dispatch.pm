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
package GitWebAdmin::Dispatch;
use base 'CGI::Application::Dispatch';

use strict;
use warnings;

use FindBin;

#
# Paths:
# user/uid
# group/gid
# repo/path

sub dispatch_args {
  return {
    debug => 0,
    prefix  => 'GitWebAdmin',
    args_to_new => {
      PARAMS => {
        cfg_file => [ "$FindBin::Bin/../gitwebadmin.ini" ],
      }
    },
    table   => [
      ''                     => { app => 'Home', rm => 'start' },
      'repo[get]'            => { app => 'Repository', rm => 'list' },
      'repo/create[get]'     => { app => 'Repository', rm => 'create_form' },
      'repo/create[post]'    => { app => 'Repository', rm => 'create' },
      'repo/create[put]'     => { app => 'Repository', rm => 'create' },
      'repo/*[get]'          => { app => 'Repository', rm => 'do', '*' => 'repo_path' },
      'repo/*[post]'         => { app => 'Repository', rm => 'do', '*' => 'repo_path' },
      'repo/*[put]'          => { app => 'Repository', rm => 'create', '*' => 'repo_path' },
      'repo/*[delete]'       => { app => 'Repository', rm => 'delete', '*' => 'repo_path' },
      'user/:id/key[put]'    => { app => 'User', rm => 'add_key' },
      'user/:id/key[post]'   => { app => 'User', rm => 'add_key' },
      'user/:id/key/:kid[get]'    => { app => 'User', rm => 'display_key' },
      'user/:id/key/:kid[post]'   => { app => 'User', rm => 'change_key' },
      'user/:id/key/:kid[delete]' => { app => 'User', rm => 'delete_key' },
      'user/:id/groups[post]' => { app => 'User', rm => 'set_groups' },
      'user/:id/subscriptions[post]' => { app => 'User', rm => 'set_subscriptions' },
      'acl/'              => { app => 'ACL', rm => 'list' },
      ':app/create[get]'     => { rm => 'create_form' },
      ':app/create[put]'     => { rm => 'create' },
      ':app/:id[delete]'     => { rm => 'delete' },
      ':app/:id[put]'        => { rm => 'create' },
      ':app/:id'             => { rm => 'do' },
      ':app/'                => { rm => 'list' },
      ],
  };
}

1;
