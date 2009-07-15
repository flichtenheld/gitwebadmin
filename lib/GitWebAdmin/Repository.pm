#
#  Copyright (C) 2009 Astaro AG  www.astaro.com
#  All rights reserved.
#
#  Author: Frank Lichtenheld <flichtenheld@astaro.com> 07.07.2009
#
##############################################################################
package GitWebAdmin::Repository;
use base 'GitWebAdmin';

use strict;
use warnings;

use File::Spec::Functions qw(rel2abs);

use CGI::Application::Plugin::ValidateRM qw(check_rm check_rm_error_page);
use Data::FormValidator::Constraints qw(:closures);

sub find_repo {
  my $c = shift;
  my $path = shift;

  my $db = $c->param('db');
  $path ||= $c->param('repo_path');
  return unless $path;
  my $repo;
  if( $path =~ /^\d+$/ ){
    $repo = $db->resultset('Repos')->find($path);
  }else{
    $repo = $db->resultset('Repos')->search({name => $path})->first;
  }

  return $repo;
}

sub repo_path_dispatch {
  my $c = shift;

  my $path = $c->param('repo_path');
  if( $path =~ s;/permissions$;; ){
    $c->param('repo_path', $path);
    return 'permissions';
  }elsif( $path =~ s;/subscription$;; ){
    $c->param('repo_path', $path);
    return 'subscription';
  }elsif( $path !~ /\.git$/ ){
    return 'list';
  }
  return '';
}

sub list {
  my $c = shift;

  my $db = $c->param('db');
  my $path = $c->param('repo_path') || '';
  my @repos;

  my $show_private = $c->query->param('show_private');
  $show_private = ($path =~ m;^user(?:/|$); ? 'yes' : 'no')
    unless defined $show_private;
  $show_private = lc $show_private;
  my @private = ();
  if( $show_private eq 'only' ){
    @private = ( private => 1 );
  }elsif( $show_private eq 'no' ){
    @private = ( private => 0 );
  }

  my $rs = $db->resultset('ActiveRepos')->search(
    { @private },{ order_by => 'name' });
  if( $path ){
    @repos = $rs->search({name => { 'like', "$path/%" }});
  }else{
    @repos = $rs->all();
  }
  die "404 Repositories not found\n" unless @repos;

  return $c->tt_process({ path => $path, repos => \@repos });
}

sub permissions {
  my $c = shift;

  my $repo = $c->find_repo;
  die "404 Repository not found\n" unless $repo;

  if( $ENV{REQUEST_METHOD} eq 'POST' ){
    # only the owner can edit the repository
    die "403 Not authorized\n"
      unless $c->has_admin($repo);

    my ($w_groups, $r_groups) =
      $c->get_writable_readable('Groups', 'w_groups', 'r_groups');
    $repo->set_w_groups($w_groups);
    $repo->set_r_groups($r_groups);
  }else{
    #FIXME
    die "405 Method not allowed\n";
  }

  return $c->redirect($c->url('repo/' . $repo->name, '', 'permissions'));
}

sub subscription {
  my $c = shift;

  if( my $d = $c->rest_dispatch({ delete => 'unsubscribe', put => 'subscribe' })){
    return $c->$d();
  }
  my $repo = $c->find_repo;
  die "404 Repository not found\n" unless $repo;
  die "405 Method not allowed\n";
}

sub subscribe {
  my $c = shift;

  my $repo = $c->find_repo;
  die "404 Repository not found\n" unless $repo;
  die "403 Not authorized for subscribing\n" unless $c->can_subscribe;

  $repo->add_to_subscribers($c->param('user_obj'));
  return $c->redirect($c->url('repo/' . $repo->name));
}

sub unsubscribe {
  my $c = shift;

  my $repo = $c->find_repo;
  die "404 Repository not found\n" unless $repo;

  $repo->remove_from_subscribers($c->param('user_obj'));
  return $c->redirect($c->url('repo/' . $repo->name));
}

sub do {
  my $c = shift;

  if( my $d = $c->repo_path_dispatch ){
    return $c->$d();
  }
  if( my $d = $c->rest_dispatch({ delete => 'delete', put => 'create' })){
    return $c->$d();
  }
  my $repo = $c->find_repo;
  die "404 Repository not found\n" unless $repo;

  my $changed = -1;
  if( $ENV{REQUEST_METHOD} eq 'POST' ){
    # only the owner can edit the repository
    die "403 Not authorized\n"
      unless $c->has_change($repo);

    # owner can always change description
    $repo->descr($c->query->param('description'));

    if( $c->has_admin($repo) ) {
      # the following things can only be changed
      # by admins and owners in private repositories
      $repo->branch($c->query->param('branch'));

      if( $c->query->param('mirrorof') ){
        my $mirrorof = $c->query->param('mirrorof');
        $mirrorof =~ s/^\s+//;
        $mirrorof =~ s/\s+$//;
        unless( $mirrorof =~ m;^(git|https?|ssh)://;i ){
          die "400 Invalid mirror URI\n";
        }
        $repo->mirrorof($mirrorof);
      }
      foreach my $opt (qw(gitweb daemon)){
        $repo->set_column(
          $opt,
          $c->get_checkbox_opt($opt)
          );
      }
    }
    if( $c->is_admin ){
      # these values can only be changed by real admins
      $repo->owner($c->query->param('owner'));
      $repo->mantis($c->get_checkbox_opt('mantis'));
      $repo->private($c->get_checkbox_opt('private'));
    }
    if( $repo->is_changed ){
      $repo->update->discard_changes;
      $changed = 1;
    }else{
      $changed = 0;
    }
  }
  my $form = $c->query->param('_form') || '';
  if( $form =~ /^\w+$/){
    return $c->tt_process("GitWebAdmin/Repository/$form.tmpl",
                          { repo => $repo, changed => $changed });
  }

  return $c->tt_process({ repo => $repo, changed => $changed });
}

sub create_form {
  my $c = shift;
  my $errs = shift;

  return $c->tt_process($errs);
}

sub _create_params {
  return {
    required => [qw(path)],
    optional => [qw(owner description branch options forkof mirrorof)],
    defaults => {
      branch => 'master',
    },
    constraint_methods => {
      mirrorof => [
        {
          name => 'URI_type',
          constraint_method => qr{^(git|https?|ssh)://}i,
        },{
          name => 'URI_chars',
          constraint_method => qr{^\S+$},
        }],
      path => [
        {
          name => 'path_abs',
          constraint_method => qr{^[^/]},
        },{
          name => 'path_git',
          constraint_method => qr{(?<=\.git)$},
        }],
      description => FV_max_length(200),
    },
    msgs => {
      constraints => {
        URI_type => 'unsupported URI type (supported: git/http/ssh)',
        URI_chars => 'contains characters not allowed in URIs',
        path_abs => "repository path can't be absolute",
        path_git => "repository path has to end in .git",
      }
    }
  };
}

sub create {
  my $c = shift;

  my $params = $c->check_rm('create_form', '_create_params')
    or return $c->check_rm_error_page;

  my $path = $params->valid('path');
  my $repo = $c->find_repo($path);
  die "409 Repository $path already exists\n" if $repo;

  my %opts = (
    name => $path,
    owner => $params->valid('owner') || '',
    descr => $params->valid('description') || '',
    );
  foreach my $opt (qw(private daemon gitweb mantis)){
    $opts{$opt} = $c->get_checkbox_opt($opt);
  }
  foreach my $opt (qw(forkof mirrorof branch)){
    $opts{$opt} = $params->valid($opt)
      if $params->valid($opt);
  }

  my $base_dir = $c->cfg('gitosis')->{repositories}
    or die "500 Config error\n";
  my $abs = rel2abs($opts{name}, $base_dir);
  unless( $abs =~ m;^\Q$base_dir\E/; ){
    die "403 Repository path $abs can't traverse outside base directory\n";
  }
  if( $abs =~ m;(/|^)..(/|$); ){
    die "400 Malformed path\n";
  }
  unless( $c->is_admin ){
    my $username = $c->param('user');
    unless( $opts{name} =~ m;^\Quser/$username/\E; ){
      die "403 Not authorized\n";
    }
    $opts{private} = 1;
    $opts{mantis} = 0;
    $opts{owner} = $username;
  }

  my $rs = $c->param('db')->resultset('Repos');
  my $new_repo = $rs->create({ %opts });

  return $c->redirect($c->url('repo/' . $new_repo->name));
}

sub delete {
  my $c = shift;

  my $repo = $c->find_repo;
  die "404 Repository not found\n" unless $repo;
  die "403 Not authorized\n" unless $c->has_admin($repo);
  die "404 Repository already deleted\n" if $repo->deleted;
  die "409 Repository has forks\n" if $repo->repo->count;

  $repo->deleted(1);
  $repo->name("Attic/".time."/".$repo->name);
  $repo->gitweb(0);
  $repo->daemon(0);
  $repo->mantis(0);
  $repo->set_w_groups([]);
  $repo->set_r_groups([]);
  $repo->update->discard_changes;

  return $c->tt_process({ repo => $repo });
}

1;
