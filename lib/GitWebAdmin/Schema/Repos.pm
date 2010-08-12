package GitWebAdmin::Schema::Repos;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

GitWebAdmin::Schema::Repos

=cut

__PACKAGE__->table("repos");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'repos_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 descr

  data_type: 'text'
  is_nullable: 1

=head2 branch

  data_type: 'text'
  default_value: 'master'
  is_nullable: 0

=head2 private

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 daemon

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 gitweb

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 mantis

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 owner

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 forkof

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 mirrorof

  data_type: 'text'
  is_nullable: 1

=head2 mirrorupd

  data_type: 'integer'
  default_value: 86400
  is_nullable: 1

=head2 deleted

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "repos_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "descr",
  { data_type => "text", is_nullable => 1 },
  "branch",
  { data_type => "text", default_value => "master", is_nullable => 0 },
  "private",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "daemon",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "gitweb",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "mantis",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "owner",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "forkof",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "mirrorof",
  { data_type => "text", is_nullable => 1 },
  "mirrorupd",
  { data_type => "integer", default_value => 86400, is_nullable => 1 },
  "deleted",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("repos_name_key", ["name"]);

=head1 RELATIONS

=head2 branches

Type: has_many

Related object: L<GitWebAdmin::Schema::Branches>

=cut

__PACKAGE__->has_many(
  "branches",
  "GitWebAdmin::Schema::Branches",
  { "foreign.rid" => "self.id" },
  {},
);

=head2 logs_pushes

Type: has_many

Related object: L<GitWebAdmin::Schema::LogsPush>

=cut

__PACKAGE__->has_many(
  "logs_pushes",
  "GitWebAdmin::Schema::LogsPush",
  { "foreign.rid" => "self.id" },
  {},
);

=head2 push_acls

Type: has_many

Related object: L<GitWebAdmin::Schema::PushAcl>

=cut

__PACKAGE__->has_many(
  "push_acls",
  "GitWebAdmin::Schema::PushAcl",
  { "foreign.repo" => "self.id" },
  {},
);

=head2 readables

Type: has_many

Related object: L<GitWebAdmin::Schema::Readable>

=cut

__PACKAGE__->has_many(
  "readables",
  "GitWebAdmin::Schema::Readable",
  { "foreign.rid" => "self.id" },
  {},
);

=head2 forkof

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Repos>

=cut

__PACKAGE__->belongs_to("forkof", "GitWebAdmin::Schema::Repos", { id => "forkof" });

=head2 repo

Type: has_many

Related object: L<GitWebAdmin::Schema::Repos>

=cut

__PACKAGE__->has_many(
  "repo",
  "GitWebAdmin::Schema::Repos",
  { "foreign.forkof" => "self.id" },
  {},
);

=head2 owner

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Users>

=cut

__PACKAGE__->belongs_to("owner", "GitWebAdmin::Schema::Users", { uid => "owner" });

=head2 repo_triggers

Type: has_many

Related object: L<GitWebAdmin::Schema::RepoTriggers>

=cut

__PACKAGE__->has_many(
  "repo_triggers",
  "GitWebAdmin::Schema::RepoTriggers",
  { "foreign.rid" => "self.id" },
  {},
);

=head2 subscriptions

Type: has_many

Related object: L<GitWebAdmin::Schema::Subscriptions>

=cut

__PACKAGE__->has_many(
  "subscriptions",
  "GitWebAdmin::Schema::Subscriptions",
  { "foreign.rid" => "self.id" },
  {},
);

=head2 writables

Type: has_many

Related object: L<GitWebAdmin::Schema::Writable>

=cut

__PACKAGE__->has_many(
  "writables",
  "GitWebAdmin::Schema::Writable",
  { "foreign.rid" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-08-12 17:07:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RoksWS2hvi2NfmM9AHwUiA

__PACKAGE__->many_to_many('w_groups' => 'writables', 'gid');
__PACKAGE__->many_to_many('r_groups' => 'readables', 'gid');
__PACKAGE__->many_to_many('subscribers' => 'subscriptions', 'uid');
__PACKAGE__->many_to_many('triggers' => 'repo_triggers', 'tid');

use GitWebAdmin::Utils qw(json_bool);
sub TO_JSON {
  my ($self) = @_;

  my @optional;
  if( $self->mirrorof ){
    push @optional, (
      mirrorof => $self->mirrorof,
      mirror_intervall => int($self->mirrorupd),
    );
  }
  if( $self->forkof ){
    push @optional, (
      fork_of => $self->forkof->name
    );
  }

  return { id => int($self->id), name => $self->name,
           description => $self->descr,
           owner => $self->owner->uid,
           default_branch => $self->branch,
           private => json_bool($self->private),
           daemon => json_bool($self->daemon),
           gitweb => json_bool($self->gitweb),
           mantis => json_bool($self->mantis),
           groups_write_access => [ map { $_->gid } $self->w_groups ],
           groups_read_access => [ map { $_->gid } $self->r_groups ],
           @optional
  };
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
