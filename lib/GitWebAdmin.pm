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

  # CGI.pm is from last millenium...
  $c->header_add(-charset => 'utf-8');

  my $db_cfg = $c->cfg('database');
  my $schema = GitWebAdmin::Schema->connect(
    "dbi:$db_cfg->{driver}:dbname=$db_cfg->{name}",
    $db_cfg->{username}, $db_cfg->{password});
  $c->param('db', $schema);
  $c->param('user', lc($ENV{REMOTE_USER})) if $ENV{REMOTE_USER};
  $c->param('user_obj', $schema->resultset('Users')->find($c->param('user')));

  $c->run_modes([qw(do list start delete create create_form)]);
  #fake run mode for easier error reporting
  $c->run_modes([qw(prerun_error)]);
  if( not $c->param('user_obj') ){
    $c->prerun_mode('prerun_error');
    $c->param('prerun_error_str', '500 Login user does not exist in database');
  }elsif( not $c->param('user_obj')->active ){
    $c->prerun_mode('prerun_error');
    $c->param('prerun_error_str', '403 Account deactivated');
  }
  $c->error_mode('handle_error');
}

sub cgiapp_init {
  my $c = shift;

  # Set some defaults for DFV unless they already exist.
  $c->param('dfv_defaults') or
    $c->param('dfv_defaults', {
      missing_optional_valid => 1,
      filters => 'trim',
      msgs => {
        any_errors => 'err_params',
        prefix     => 'err_',
        invalid    => 'Invalid',
        missing    => 'Missing',
        invalid_separator => ' <br> ',
        format => '<span class="dfv-errors">%s</span>',
      },
   });

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
  $anchor = '' unless defined $anchor;
  if( $anchor ){
    $anchor = '#'.uri_escape($anchor);
  }
  $url = uri_escape($url, "^A-Za-z0-9\-_.!~*'()/");
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

sub get_obj_list {
  my ($c, $table, $param) = @_;

  my %objs = map { $_ => 1 } $c->query->param($param);
  delete $objs{none};
  my $rs = $c->param('db')->resultset($table);
  my @objs = map { $rs->find($_) } keys %objs;

  return \@objs;
}

sub get_writable_readable {
  my ($c, $table, $w_param, $r_param) = @_;

  my %w = map { $_ => 1 } $c->query->param($w_param);
  my %r = map { $_ => 1 } $c->query->param($r_param);
  delete $w{none};
  delete $r{none};
  foreach my $key (keys %w) {
    delete $r{$key};
  }
  my $rs = $c->param('db')->resultset($table);
  my @w = map { $rs->find($_) } keys %w;
  my @r = map { $rs->find($_) } keys %r;

  return \@w, \@r;
}

sub is_admin {
  my $c = shift;

  return if not $c->param('user_obj')->active;
  return $c->param('user_obj')->admin;
}

sub has_admin {
  my ($c, $repo) = @_;

  my $user = $c->param('user_obj') or return 0;
  return 0 unless $user->active;
  return 1 if $user->admin;
  return 1 if $repo->private and
    $repo->owner->uid eq $user->uid;

  return 0;
}

sub has_change {
  my ($c, $repo) = @_;

  my $user = $c->param('user_obj') or return 0;
  return 0 unless $user->active;
  return 1 if $user->admin;
  return 1 if $repo->owner->uid eq $user->uid;

  return 0;
}

sub can_subscribe {
  my ($c, $repo) = @_;

  my $user = $c->param('user_obj') or return 0;
  return 0 unless $user->active;

  return 1 if $c->has_readable($repo);
  # world-readable anyway
  return 1 if $repo->gitweb or $repo->daemon;

  return 0;
}

sub has_writable {
  my ($c, $repo) = @_;

  my $user = $c->param('user_obj') or return 0;
  return 0 unless $user->active;
  return 1 if $repo->owner->uid eq $user->uid;
  foreach my $w ($repo->w_groups){
    foreach my $u ($w->users){
      return 1 if $user->uid eq $u->uid;
    }
  }
  return 0;
}

sub has_readable {
  my ($c, $repo) = @_;

  my $user = $c->param('user_obj') or return 0;
  return 0 unless $user->active;
  return 1 if $c->has_writable($repo);
  foreach my $r ($repo->r_groups){
    foreach my $u ($r->users){
      return 1 if $user->uid eq $u->uid;
    }
  }
  return 0;
}

sub is_subscribed {
  my ($c, $repo) = @_;

  my $user = $c->param('user_obj') or return 0;
  my @res = $repo->subscriptions({ uid => $user->uid });
  return scalar @res;
}

1;
