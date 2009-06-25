package GitWebAdmin::Dispatch;
use base 'CGI::Application::Dispatch';

use strict;
use warnings;

#
# Paths:
# user/uid
# group/gid
# repo/path

sub dispatch_args {
  return {
    debug => 1,
    prefix  => 'GitWebAdmin',
    auto_rest_lc => 1,
    args_to_new => {
      PARAMS => {
        cfg_file => [ '/home/flichtenheld/git/git-web-admin/gitwebadmin.ini' ],
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
      'user/:id/key[post]'   => { app => 'User', rm => 'change_key' },
      'user/:id/key[delete]' => { app => 'User', rm => 'delete_key' },
      ':app/:id'  => { rm => 'do' },
      ':app/'     => { rm => 'list' },
      ],
  };
}

1;
