package GitWebAdmin::Schema::PushAcl;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

GitWebAdmin::Schema::PushAcl

=cut

__PACKAGE__->table("push_acl");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'push_acl_id_seq'

=head2 priority

  data_type: 'integer'
  is_nullable: 0

=head2 user

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=head2 group

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=head2 repo

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 user_flags

  data_type: 'text'
  is_nullable: 1

=head2 repo_flags

  data_type: 'text'
  is_nullable: 1

=head2 ref

  data_type: 'text'
  is_nullable: 1

=head2 action

  data_type: 'push_action_type'
  is_nullable: 1
  size: 4

=head2 result

  data_type: 'acl_result_type'
  default_value: 'deny'
  is_nullable: 0
  size: 4

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "push_acl_id_seq",
  },
  "priority",
  { data_type => "integer", is_nullable => 0 },
  "user",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
  "group",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
  "repo",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "user_flags",
  { data_type => "text", is_nullable => 1 },
  "repo_flags",
  { data_type => "text", is_nullable => 1 },
  "ref",
  { data_type => "text", is_nullable => 1 },
  "action",
  { data_type => "push_action_type", is_nullable => 1, size => 4 },
  "result",
  {
    data_type => "acl_result_type",
    default_value => "deny",
    is_nullable => 0,
    size => 4,
  },
  "comment",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("push_acl_priority_key", ["priority"]);

=head1 RELATIONS

=head2 group

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Groups>

=cut

__PACKAGE__->belongs_to("group", "GitWebAdmin::Schema::Groups", { gid => "group" });

=head2 user

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Users>

=cut

__PACKAGE__->belongs_to("user", "GitWebAdmin::Schema::Users", { uid => "user" });

=head2 repo

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Repos>

=cut

__PACKAGE__->belongs_to("repo", "GitWebAdmin::Schema::Repos", { id => "repo" });


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-08-12 17:07:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jkUaioBRe0PtI6EVvqOICw

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
