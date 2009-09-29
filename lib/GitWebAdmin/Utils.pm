#
#  Copyright (C) 2009 Astaro AG  www.astaro.com
#  All rights reserved.
#
#  Author: Frank Lichtenheld <flichtenheld@astaro.com> 28.08.2009
#
##############################################################################
package GitWebAdmin::Utils;

use base 'Exporter';

our @EXPORT_OK = qw(short_id json_bool);

use strict;
use warnings;

use File::Path;
use File::Spec::Functions qw(catfile);
use File::Slurp;
use File::Temp qw(tempfile);
use JSON::XS;
use LWP::UserAgent;
use URI::Escape;

sub check_key {
  my ($key) = @_;

  my ($fh, $fname) = tempfile();
  write_file($fh, \$key)
    or die "500 Error during key check\n";
  open my $out, '-|', qw(ssh-keygen -l -f), $fname
    or die "500 Error during key check\n";
  my $line = <$out>;
  close $out or return;
  if( $line =~ /^(\d+) ((?:[0-9a-f]{2}:){15}[0-9a-f]{2}) \Q$fname\E \(([DR]SA)\)$/ ){
    return ($1, $2, $3);
  }elsif( $line =~ /^(\d+) ((?:[0-9a-f]{2}:){15}[0-9a-f]{2}) \Q$fname\E$/ ){
    # older ssh-keygen doesn't display the type
    return ($1, $2, undef);
  }
  return;
}

# Update commit lists
# Always operate on whole repo, not just the updated branches. Usually it
# will make no difference and noticing that should be cheap enough.
##
my $mantis_url = 'http://mantis.intranet.astaro.de';
sub update_mantis_data {
  my ($git_repo, $db_repo) = @_;

  my %branches = map { $_->branch => $_ } $db_repo->branches;

  my @heads = $git_repo->command(qw(for-each-ref refs/heads));
  foreach( @heads ){
    unless( m|^([a-f0-9]{40})\s+commit\s+refs/heads/(.+)$| ){
      warn "unknown format for for-each-ref output: $_\n";
      next;
    }
    my ($sha1, $ref) = ($1, $2);
    if( not exists $branches{$ref} ){
      my $branch = $db_repo->create_related('branches',
                                            { branch => $ref, commit => '0'x40 });
      import_commits($git_repo, $db_repo, $branch, $sha1);

      $branch->commit($sha1);
      $branch->update->discard_changes;

      print "Mantis Data: Added branch $ref (".short_id($sha1).")\n";
    } else {
      my $old_sha1 = $branches{$ref}->commit;
      unless( $old_sha1 eq $sha1 ){
        import_commits($git_repo, $db_repo, $branches{$ref}, $sha1, $old_sha1);

        $branches{$ref}->commit($sha1);
        $branches{$ref}->update->discard_changes;

        print "Mantis Data: Updated branch $ref (".short_id($old_sha1)."..".short_id($sha1).")\n";
      }
    }
  }
  my $mantisdata = catfile( '/srv/git/mantis/', $db_repo->name );
  if( ! -d $mantisdata ){
    mkpath $mantisdata, 0, 02777
      or die "mkdir $mantisdata failed: $!\n";
  }
  $mantisdata = catfile( $mantisdata, 'commits.txt' );
  my @data;
  foreach my $c ($db_repo->commits){
    push @data, $c->commit."=".join(',', map { $_->branch } $c->branches)."\n";
  }
  write_file("$mantisdata.new", @data)
    or die "write_file $mantisdata.new failed: $!\n";
  rename("$mantisdata.new", $mantisdata)
    or die "rename $mantisdata failed: $!\n";

  my $ua = LWP::UserAgent->new;

  my $trigger = $ua->get("$mantis_url/plugin.php?page=AstaroGitIntegration/latest&repo_url=".uri_escape($db_repo->name));

  my $success = 0;
  if( $trigger->is_success ){
    $trigger = $ua->get("$mantis_url/plugin.php?page=AstaroGitIntegration/import&repo_url=".uri_escape($db_repo->name));

    if( $trigger->is_success ){
      print "Mantis: Updated succesfully\n";
      $success = 1;
    }else{
      warn "Mantis: Astaro Update FAILED: ".$trigger->status_line."\n";
    }
  }else{
    warn "Mantis: Update FAILED: ".$trigger->status_line."\n";
  }

  return $success;
}

sub short_id {
  my ($sha) = @_;

  return substr($sha, 0, 7);
}

sub import_commits {
  my ($git_repo, $db_repo, $branch, $sha1, $old_sha1) = @_;

  my $commits = $db_repo->result_source->schema->resultset('Commits');

  my @cmd = qw(rev-list -E --grep=^\[[0-9]+\]);
  push @cmd, $sha1;
  push @cmd, "^$old_sha1" if $old_sha1;

  my @commits = $git_repo->command(@cmd);
  foreach my $c (@commits){
    chomp $c;
    warn "invalid commit $c\n" unless $c =~ /^[a-f0-9]{40}$/;
    my $commit = $commits->find_or_create(
      { rid => $db_repo->id, commit => $c },
      { key => 'commits_rid_key' }
    );
    $branch->add_to_commits($commit);
  }
}

sub call_trigger {
  my ($config, $repo, $refupd, $trigger) = @_;

  my $method = $trigger->method;
  my $uri = $trigger->uri;

  my %replace = (
    name => $repo->name,
    rid => $repo->id,
    ssh => $config->{links}{ssh},
    daemon => $config->{links}{daemon},
    ref => $refupd->ref,
    old_cid => $refupd->old_id,
    new_cid => $refupd->new_id,
    user => $refupd->uid->uid,
  );
  my $keys = join('|', keys %replace);
  # links can contain further replacements
  $uri =~ s/\%(ssh|daemon)/$replace{$1}/ige;
  $uri =~ s/\%($keys)/$replace{$1}/ige;
  if( $trigger->method eq 'ssh' ){
    my ($host, @cmd) = split /\s+/, $uri;
    warn "no command given for ssh trigger: $uri\n"
      unless @cmd;
    system('ssh', $host, @cmd) and do {
      warn "ssh trigger failed ('$uri'): $!\n";
      return;
    };
    return 1;
  }elsif( $trigger->method eq 'http' ){
    my $ua = LWP::UserAgent->new;

    my $trigger = $ua->get($uri);
    unless( $trigger->is_success ){
      warn "http trigger failed ('$uri'): ".$trigger->status_line."\n";
      return;
    }
    return 1;
  }else{
    warn "unknown trigger method $method\n";
    return;
  }
}

sub json_bool {
  my ($value) = @_;

  return $value ? JSON::XS::true : JSON::XS::false;
}

1;
