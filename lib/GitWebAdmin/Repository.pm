package GitWebAdmin::Repository;
use base 'GitWebAdmin';

use strict;
use warnings;

use List::MoreUtils qw(any);

sub setup {
  my $c = shift;

  $c->run_modes([qw(do list delete)]);
}

sub list {
  my $c = shift;

  my $db = $c->param('db');
  my $path = $c->param('repo_path');
  my @repos;
  my $rs = $db->resultset('Repos')->search({},{ order_by => 'name' });
  if( $path ){
    @repos = $rs->search({name => { 'like', "$path/%" }});
  }else{
    @repos = $rs->all();
  }
  die "404 Repositories not found\n" unless @repos;

  return $c->tt_process({ path => $path, repos => \@repos });
}

sub do {
  my $c = shift;

  my $db = $c->param('db');
  my $path = $c->param('repo_path');
  my $repo;
  if( $path !~ m;\.git$; ){
    return $c->list();
  }elsif( $path =~ /^\d+$/ ){
    $repo = $db->resultset('Repos')->find($path);
  }else{
    $repo = $db->resultset('Repos')->search({name => $path})->first;
  }
  die "404 Repository not found\n" unless $repo;

  my $changed = -1;
  if( $ENV{REQUEST_METHOD} eq 'POST' ){
    # only the owner can edit the repository
    die "403 Not authorized\n"
      unless $repo->owner->uid eq $c->param('user');

    $repo->descr($c->query->param('description'));
    foreach my $opt (qw(gitweb daemon)){
      $repo->set_column(
        $opt,
        (any { $_ eq $opt } $c->query->param('options')) ? 1 : 0
      );
    }
    if( $repo->is_changed ){
      $repo->update;
      $changed = 1;
    }else{
      $changed = 0;
    }
  }

  return $c->tt_process({ repo => $repo, changed => $changed });
}

1;
