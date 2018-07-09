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
  open my $out, '-|', qw(ssh-keygen -l -E md5 -f), $fname
    or die "500 Error during key check\n";
  my $line = <$out>;
  chomp $line;
  close $out or return;
  if( $line =~ /^(\d+) +(?:MD5:)?((?:[0-9a-f]{2}:){15}[0-9a-f]{2}) +.*? +\(([DR]SA)\)$/ ){
    return ($1, $2, $3);
  }
  die "500 Unexpected string '$line' while checking key format\n";
  return;
}

# Update branch lists
# Always operate on whole repo, not just the updated branches. Usually it
# will make no difference and noticing that should be cheap enough.
##
sub update_branch_data {
  my ($git_repo, $db_repo, $log_user) = @_;

  my $changed = 0;
  my %branches = map { $_->branch => $_ } $db_repo->branches;
  my @heads = $git_repo->command(qw(for-each-ref refs/heads));
  my %heads;
  my (%log_data , $schema, $logs);
  if( $log_user ) {
    $schema = $db_repo->result_source->schema;
    $logs = $schema->resultset('LogsPush');
    %log_data = ( rid => $db_repo->id, uid => $log_user,
                  old_id => '0'x40, new_id => '0'x40 );
  }
  foreach( @heads ){
    unless( m|^([a-f0-9]{40})\s+commit\s+refs/heads/(.+)$| ){
      warn "unknown format for for-each-ref output: $_\n";
      next;
    }
    my ($sha1, $ref) = ($1, $2);
    $heads{$ref} = $sha1;
    if( not exists $branches{$ref} ){
      my $branch = $db_repo->create_related('branches',
                                            { branch => $ref, commit => '0'x40 });

      $branch->commit($sha1);
      $branch->update->discard_changes;

      $changed++;
      print "Branch List: Added branch $ref (".short_id($sha1).")\n";
      $logs->create({ %log_data, new_id => $sha1, ref => "refs/heads/$ref" })
        if $log_user;
    } else {
      my $old_sha1 = $branches{$ref}->commit;
      unless( $old_sha1 eq $sha1 ){

        $branches{$ref}->commit($sha1);
        $branches{$ref}->update->discard_changes;

        $changed++;
        print "Branch List: Updated branch $ref (".short_id($old_sha1)."..".short_id($sha1).")\n";
        $logs->create({ %log_data,
                        old_id => $old_sha1, new_id => $sha1,
                        ref => "refs/heads/$ref" }) if $log_user;
      }
    }
  }
  # remove data for deleted branches
  foreach my $ref (sort keys %branches){
    if( not exists $heads{$ref} ){
      my $branch = $branches{$ref};

      $branch->delete;
      $changed++;
      print "Branch List: Removed branch $ref (".short_id($branch->commit).")\n";
      $logs->create({ %log_data, old_id => $branch->commit,
                      ref => "refs/heads/$ref" }) if $log_user;
    }
  }
  unless( $changed ){
    print "No branches updated\n";
  }
  return $changed;
}

sub short_id {
  my ($sha) = @_;

  return substr($sha, 0, 7);
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
  }elsif( $trigger->method eq 'local' ){
    my @cmd = split /\s+/, $uri;
    system(@cmd) and do {
      warn "local trigger failed ('$uri'): $!\n";
      return;
    };
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
