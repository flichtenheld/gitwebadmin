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
package GitWebAdmin::Repository;
use base 'GitWebAdmin';

use strict;
use warnings;

use File::Spec::Functions qw(rel2abs);

use CGI::Application::Plugin::ValidateRM qw(check_rm check_rm_error_page);
use Data::FormValidator::Constraints qw(:closures);

sub setup {
  my $c = shift;

  $c->run_modes([qw(edit_form)]);
}

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
  if( $path =~ s;/(permissions|subscription|triggers)$;; ){
    $c->param('repo_path', $path);
    return $1;
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

  return $c->json_output(\@repos) if $c->want_json;
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

sub triggers {
  my $c = shift;

  my $repo = $c->find_repo;
  die "404 Repository not found\n" unless $repo;

  if( $ENV{REQUEST_METHOD} eq 'POST' ){
    # only the owner can edit the repository
    die "403 Not authorized\n"
      unless $c->has_admin($repo);

    my $triggers = $c->get_obj_list('ExternalTriggers', 'triggers');
    $repo->set_triggers($triggers);
  }else{
    #FIXME
    die "405 Method not allowed\n";
  }

  return $c->redirect($c->url('repo/' . $repo->name, '', 'triggers'));
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
  die "403 Not authorized for subscribing\n" unless $c->can_subscribe($repo);

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

sub edit_form {
  my $c = shift;
  my $errs = shift;

  my $repo = $c->find_repo;
  die "404 Repository not found\n" unless $repo;

  return $c->tt_process('GitWebAdmin/Repository/do.tmpl', {repo => $repo, %$errs});
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

    my $params = $c->check_rm('edit_form', '_edit_params')
      or return $c->check_rm_error_page;

    # owner can always change description
    $repo->descr($params->valid('description'));
    # and default branch
    $repo->branch($params->valid('branch'));

    my $mirror = $repo->mirror;
    my $new_mirror;
    if( $c->has_admin($repo) ) {
      # the following things can only be changed
      # by admins and owners in private repositories

      if( $params->valid('mirrorof') ){
        if( $mirror ){
          $mirror->mirrorof($params->valid('mirrorof'));
          $mirror->mirrorupd($params->valid('mirrorupd'));
        }else{
          $repo->create_related('mirrors', {
            mirrorof => $params->valid('mirrorof'),
            mirrorupd => $params->valid('mirrorupd'),
                                })
            or die "500 Couldn't create mirror object\n";
          $mirror = $repo->mirror;
          $new_mirror = 1;
        }
      }elsif( $mirror ){
        $mirror->delete;
        $new_mirror = -1;
      }
      foreach my $opt (qw(gitweb daemon)){
        $repo->set_column(
          $opt,
          $c->get_checkbox_opt($opt)
          );
      }
      my %tags = map { $_ => 1 } split m/\s*,\s*/, $params->valid('tags');
      foreach my $tag ($repo->repo_tags){
        $tag->delete unless $tags{$tag->tag};
      }
      foreach my $tag (keys %tags){
        $repo->find_or_create_related('repo_tags', { tag => $tag });
      }
    }
    if( $c->is_admin ){
      # these values can only be changed by real admins
      my $db = $c->param('db');
      my $owner = $db->resultset('Users')->find($params->valid('owner'), { key => 'users_uid_key' });
      $repo->owner($owner);
      $repo->private($c->get_checkbox_opt('private'));
    }
    if( $repo->is_changed ){
      $repo->update->discard_changes;
      $changed = 1;
    }else{
      $changed = 0;
    }
    if( $mirror and $mirror->is_changed ){
      $mirror->last_error('Mirror definition changed');
      $mirror->update->discard_changes;
      $changed = 1;
    }elsif( $new_mirror ){
      $changed = 1;
    }
  }
  my $form = $c->query->param('_form') || '';
  if( $form =~ /^\w+$/){
    return $c->tt_process("GitWebAdmin/Repository/$form.tmpl",
                          { repo => $repo, changed => $changed, now => time });
  }

  return $c->json_output($repo) if $c->want_json;
  return $c->tt_process({ repo => $repo, changed => $changed, now => time });
}

sub create_form {
  my $c = shift;
  my $errs = shift;

  return $c->tt_process($errs);
}

sub __mirrorupd_range {
  my ($dfv, $val) = @_;
  $dfv->set_current_constraint_name('mirrorupd_range');
  return ($val >= 600 and $val <= 604800);
};

my $constraints = {
  mirrorof => [
    {
      name => 'URI_type',
      constraint_method => qr{^(git|https?|ssh)://}i,
    },{
      name => 'URI_chars',
      constraint_method => qr{^\S+$},
    }],
  mirrorupd => \&__mirrorupd_range,
  path => [
    {
      name => 'path_abs',
      constraint_method => qr{^[^/]},
    },{
      name => 'path_git',
      constraint_method => qr{(?<=\.git)$},
    },{
      name => 'path_chars',
      constraint_method => qr{^[a-zA-Z\d][\w@.-]+(/[a-zA-Z\d][\w@.-]+)*$},
    }],
  description => FV_max_length(200),
  tags => [
    {
      name => 'tags_chars',
      constraint_method => qr{^[\w.+-]+(?:\s*,\s*[\w.+-]+)*$},
    }],
};
my $constraint_msgs = {
  constraints => {
    URI_type => 'unsupported URI type (supported: git/http/ssh)',
    URI_chars => 'contains characters not allowed in URIs',
    mirrorupd_range => 'must be in the range 600 - 604_800',
    path_abs => "repository path can't be absolute",
    path_git => "repository path has to end in .git",
    path_chars => "repository path can only contain letters, numbers and characters @.-",
    tags_chars => "tags are a comma-separated list of words that contain letters, numbers, and characters .+-",
  }
};

sub _edit_params {
  return {
    required => [qw(description branch)],
    optional => [qw(owner options tags forkof mirrorof mirrorupd _form)],
    defaults => {
      branch => 'master',
      mirrorupd => 86_400,
    },
    constraint_methods => $constraints,
    msgs => $constraint_msgs,
  };
}

sub _create_params {
  return {
    required => [qw(path)],
    optional => [qw(owner description branch options tags forkof mirrorof mirrorupd)],
    defaults => {
      branch => 'master',
      mirrorupd => 86_400,
    },
    constraint_methods => $constraints,
    msgs => $constraint_msgs,
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
  foreach my $opt (qw(private daemon gitweb)){
    $opts{$opt} = $c->get_checkbox_opt($opt);
  }
  foreach my $opt (qw(forkof branch)){
    $opts{$opt} = $params->valid($opt)
      if $params->valid($opt);
  }
  my %mirror_opts = ();
  foreach my $opt (qw(mirrorof mirrorupd)){
    $mirror_opts{$opt} = $params->valid($opt)
      if $params->valid($opt);
  }

  my $base_dir = $c->cfg('gitosis')->{repositories}
    or die "500 Config error\n";
  my $abs = rel2abs($opts{name}, $base_dir);
  unless( $abs =~ m;^\Q$base_dir\E/; ){
    die "403 Repository path $abs can't traverse outside base directory\n";
  }
  if( $abs =~ m;(/|^)\.\.(/|$); ){
    die "400 Malformed path\n";
  }
  if( $c->is_admin ){
    $opts{owner} = $c->param('db')->resultset('Users')->find(
      $opts{owner},{ key => 'users_uid_key' })->id
      or die "400 Invalid owner\n";
  }else{
    my $username = $c->param('user');
    unless( $opts{name} =~ m;^\Quser/$username/\E; ){
      die "403 Not authorized\n";
    }
    $opts{private} = 1;
    $opts{owner} = $c->param('user_obj')->id;
  }
  my $rs = $c->param('db')->resultset('Repos');
  if( $opts{forkof} ){
    my $forked = $rs->find($opts{forkof})
      or die "404 Repository to fork doesn't exist\n";

    unless( $c->has_readable($forked) ){
      die "403 Not authorized to fork\n";
    }
  }
  $opts{repo_tags} = [
    map { { tag => $_ } } split m/\s*,\s*/, $params->valid('tags') ];
  my $new_repo = $rs->create({ %opts });
  if( %mirror_opts && $mirror_opts{mirrorof} ){
    $new_repo->create_related('mirrors', { %mirror_opts })
      or die "500 Couldn't create mirror object\n";
  }

  return $c->redirect($c->url('repo/' . $new_repo->name));
}

sub delete {
  my $c = shift;

  my $repo = $c->find_repo;
  die "404 Repository not found\n" unless $repo;
  die "403 Not authorized\n" unless $c->has_admin($repo);
  die "404 Repository already deleted\n" if $repo->deleted;
  die "409 Repository has forks\n" if $repo->repo({ deleted => 0 })->count;

  $repo->deleted(1);
  $repo->name("Attic/".time."/".$repo->name);
  $repo->gitweb(0);
  $repo->daemon(0);
  $repo->set_w_groups([]);
  $repo->set_r_groups([]);
  $repo->set_triggers([]);
  $repo->update->discard_changes;

  return $c->tt_process({ repo => $repo });
}

1;
