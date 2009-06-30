package GitWebAdmin;
use base 'CGI::Application';

use strict;
use warnings;

use URI::Escape;
use List::MoreUtils qw(any);
use FindBin;

use CGI::Application::Plugin::TT;
use CGI::Application::Plugin::ConfigAuto qw(cfg);
use CGI::Application::Plugin::Redirect;

use GitWebAdmin::Schema;

GitWebAdmin->tt_config(
  TEMPLATE_OPTIONS => {
    INCLUDE_PATH => "$FindBin::Bin/../templates",
    POST_CHOMP   => 1,
    VARIABLES => {
      DBIxRel => sub {my $res=shift or return []; return $res if ref $res eq 'ARRAY'; return [ $res ] },
    },
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
  $c->param('user_obj', $schema->resultset('Users')->find($c->param('user')));

  $c->run_modes([qw(do list start)]);
  #fake run mode for easier error reporting
  $c->run_modes([qw(prerun_error)]);
  unless( $c->param('user_obj') ){
    $c->prerun_mode('prerun_error');
    $c->param('prerun_error_str', '500 Login user does not exist in database');
  }
  $c->error_mode('handle_error');
}

sub handle_error {
  my ($c, $error) = @_;

  if( $error =~ s/^(\d{3})\s// ){
    $c->header_props(-status => $1);
  }
  return $c->tt_process('error.tmpl', { error => $error });
}

sub prerun_error {
  die shift->param('prerun_error_str')."\n";
}

sub rest_dispatch {
  my ($c, $methods) = @_;

  my $method_override = $c->query->param('_method');
  return unless $method_override;
  return $methods->{$method_override};
}

sub url {
  my ($c, $url, $params, $anchor) = @_;

  my $home = $c->cfg('setup')->{homepage} || '';
  $anchor //= '';
  if( $anchor ){
    $anchor = '#'.uri_escape($anchor);
  }
  my @params;
  if( $params and ref $params eq 'HASH' ){
    foreach my $key (keys %$params){
      push @params, uri_escape($key).'='.uri_escape($params->{$key});
    }
    return $home . $url . '?' . join(';', @params) . $anchor;
  }
  return $home . $url . $anchor;
}

sub get_checkbox_opt {
  my ($c, $option, $boxes) = @_;
  $boxes ||= 'options';

  if( any { $_ eq $option } $c->query->param('options') ){
    return 1;
  }
  return 0;
}

sub is_admin {
  my $c = shift;

  return $c->param('user_obj')->admin;
}

1;
