package GitWebAdmin;
use base 'CGI::Application';

use strict;
use warnings;

use CGI::Application::Plugin::TT;
use CGI::Application::Plugin::ConfigAuto qw(cfg);
use GitWebAdmin::Schema;

GitWebAdmin->tt_config(
  TEMPLATE_OPTIONS => {
    INCLUDE_PATH => '/home/flichtenheld/git/git-web-admin/templates',
    POST_CHOMP   => 1,
  },
);

sub cgiapp_prerun {
  my $c = shift;
  my $db_cfg = $c->cfg('database');
  my $schema = GitWebAdmin::Schema->connect(
    "dbi:$db_cfg->{driver}:dbname=$db_cfg->{name}",
    $db_cfg->{username}, $db_cfg->{password});
  $c->param('db', $schema);
  $c->param('user', $ENV{REMOTE_USER}) if $ENV{REMOTE_USER};

  $c->run_modes([qw(do list start)]);
  $c->error_mode('handle_error');
}

sub handle_error {
  my ($c, $error) = @_;

  if( $error =~ s/^(\d{3})\s// ){
    $c->header_props(-status => $1);
  }
  return $c->tt_process('error.tmpl', { error => $error });
}

sub url {
  my ($c, $url) = @_;

  my $home = $c->cfg('setup')->{homepage} || '';
  return $home . $url;
}

1;
