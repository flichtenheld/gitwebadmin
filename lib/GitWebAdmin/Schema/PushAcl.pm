package GitWebAdmin::Schema::PushAcl;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("push_acl");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('push_acl_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "priority",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "user",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "group",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "repo",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "user_flags",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "repo_flags",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "ref",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "action",
  {
    data_type => "push_action_type",
    default_value => undef,
    is_nullable => 1,
    size => 4,
  },
  "result",
  {
    data_type => "acl_result_type",
    default_value => "'deny'::acl_result_type",
    is_nullable => 0,
    size => 4,
  },
  "comment",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("push_acl_priority_key", ["priority"]);
__PACKAGE__->add_unique_constraint("push_acl_pkey", ["id"]);
__PACKAGE__->belongs_to("group", "GitWebAdmin::Schema::Groups", { gid => "group" });
__PACKAGE__->belongs_to("user", "GitWebAdmin::Schema::Users", { uid => "user" });
__PACKAGE__->belongs_to("repo", "GitWebAdmin::Schema::Repos", { id => "repo" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-01-11 22:33:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ALGanwUy5ilhywKg9PPECQ

use List::MoreUtils qw(none);
use Data::Dumper;

sub acl2str {
  my ($self) = @_;

  my $str = sprintf("[%d (id=%d)] => %s (%s)\n", $self->priority, $self->id, $self->result, $self->comment||'');
  my %params;
  $params{user}       = $self->user->uid if $self->user;
  $params{group}      = $self->group->gid if $self->group;
  $params{action}     = $self->action if $self->action;
  $params{repo}       = $self->repo->name if $self->repo;
  $params{repo_flags} = $self->repo_flags if $self->repo_flags;
  $params{user_flags} = $self->user_flags if $self->user_flags;
  $params{ref}        = $self->ref if $self->ref;
  $str .= Data::Dumper->Dump([\%params], [qw(*acl_params)]);

  return $str;
}

sub check_acl {
  my ($self, $params) = @_;

  return if $params->{repo}   and $self->repo
    and $self->repo->id    != $params->{repo}->id;
  return if $params->{user}   and $self->user
    and $self->user->uid   ne $params->{user}->uid;
  return if $params->{user}  and $self->group
    and none { $self->group->gid eq $_->gid } $params->{user}->groups;
  return if $params->{action} and $self->action
    and $self->action      ne $params->{action};
  if( $params->{user} and $self->user_flags ){
    return unless $self->_check_user_flags($params);
  }
  if( $params->{repo} and $self->repo_flags ){
    return unless $self->_check_repo_flags($params->{repo});
  }
  if( $params->{ref} and $self->ref ){
    my $regex = $self->ref;
    return unless $params->{ref} =~ /^$regex$/;
  }
  return $self->result;
}

# return true if the user flags match the given user
sub _check_user_flags {
  my ($self, $params) = @_;

  my @flags = split m/,/, $self->user_flags;
  foreach my $flag (@flags){
    my $negated = ($flag =~ s/^!// ? 1 : 0);
    if( $flag =~ /^(admin|active)$/ ){
      return unless $self->_check_column_flag($params->{user}, $flag, $negated);
    }elsif( $flag eq 'owner' ){
      if( $params->{repo} ){
        my $is_owner = $params->{user}->uid eq $params->{repo}->owner->uid;
        return if $is_owner and $negated;
        return if !$is_owner and !$negated;
      }
    }else{
      die "Unknown flag\n";
    }
  }
  return 1;
}

# return true if the repo flags match the given repo
sub _check_repo_flags {
  my ($self, $repo) = @_;

  my @flags = split m/,/, $self->repo_flags;
  foreach my $flag (@flags){
    my $negated = ($flag =~ s/^!// ? 1 : 0);
    if( $flag =~ /^(deleted|private|daemon|gitweb|mantis|mirrorof|forkof)$/ ){
      return unless $self->_check_column_flag($repo, $flag, $negated);
    }else{
      die "Unknown flag\n";
    }
  }
  return 1;
}


sub _check_column_flag {
  my ($self, $object, $column, $negated) = @_;

  my $value = $object->get_column($column);
  return if $value and $negated;
  return if !$value and !$negated;
  return 1;
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
