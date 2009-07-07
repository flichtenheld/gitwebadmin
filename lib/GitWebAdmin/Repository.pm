package GitWebAdmin::Repository;
use base 'GitWebAdmin';

use strict;
use warnings;

use File::Spec::Functions qw(rel2abs);
use Cwd qw(realpath);

sub find_repo {
  my $c = shift;

  my $db = $c->param('db');
  my $path = $c->param('repo_path');
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

    $repo->descr($c->query->param('description'));
    foreach my $opt (qw(gitweb daemon)){
      $repo->set_column(
        $opt,
        $c->get_checkbox_opt($opt)
      );
    }
    if( $c->is_admin ){
      $repo->owner($c->query->param('owner'));
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
  return shift->tt_process();
}

sub create {
  my $c = shift;

  my $repo = $c->find_repo;
  die "409 Repository already exists\n" if $repo;

  my %opts = (
    name => $c->query->param('path') || '',
    owner => $c->query->param('owner') || '',
    descr => $c->query->param('description') || '',
    );
  foreach my $opt (qw(private daemon gitweb)){
    $opts{$opt} = $c->get_checkbox_opt($opt);
  }
  $opts{forkof} = $c->query->param('forkof')
    if $c->query->param('forkof');
  $opts{mirrorof} = $c->query->param('mirrorof')
    if $c->query->param('mirrorof');

  # Validity and Authorization checks
  if( $opts{mirrorof} ){
    $opts{mirrorof} =~ s/^\s+//;
    $opts{mirrorof} =~ s/\s+$//;
    unless( $opts{mirrorof} =~ m;^(git|https?|ssh)://;i ){
      die "400 Invalid mirror URI\n";
    }
  }

  unless( $opts{name} =~ m/\.git$/ ){
    die "400 Repository path does not end in .git\n";
  }
  if( $opts{name} =~ m;^/; ){
    die "403 Repository path can't be absolute\n";
  }
  my $base_dir = $c->cfg('gitosis')->{repositories}
    or die "500 Config error\n";
  my $abs = rel2abs($opts{name}, $base_dir);
  $abs = realpath($abs);
  unless( $abs =~ m;^\Q$base_dir\E/; ){
    die "403 Repository path can't traverse outside base directory\n";
  }
  unless( $c->is_admin ){
    my $username = $c->param('user');
    unless( $opts{name} =~ m;^\Quser/$username/\E; ){
      die "403 Not authorized\n";
    }
    $opts{private} = 1;
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
  $repo->set_w_groups([]);
  $repo->set_r_groups([]);
  $repo->update->discard_changes;

  return $c->tt_process({ repo => $repo });
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
