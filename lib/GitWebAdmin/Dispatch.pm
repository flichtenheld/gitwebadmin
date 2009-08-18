#
#  Copyright (C) 2009 Astaro AG  www.astaro.com
#  All rights reserved.
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
