package GitWebAdmin::Schema::ActiveRepos;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

GitWebAdmin::Schema::ActiveRepos

=cut

__PACKAGE__->table("active_repos");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 descr

  data_type: 'text'
  is_nullable: 1

=head2 private

  data_type: 'boolean'
  is_nullable: 1

=head2 daemon

  data_type: 'boolean'
  is_nullable: 1

=head2 gitweb

  data_type: 'boolean'
  is_nullable: 1

=head2 forkof

  data_type: 'integer'
  is_nullable: 1

=head2 deleted

  data_type: 'boolean'
  is_nullable: 1

=head2 branch

  data_type: 'text'
  is_nullable: 1

=head2 owner

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "descr",
  { data_type => "text", is_nullable => 1 },
  "private",
  { data_type => "boolean", is_nullable => 1 },
  "daemon",
  { data_type => "boolean", is_nullable => 1 },
  "gitweb",
  { data_type => "boolean", is_nullable => 1 },
  "forkof",
  { data_type => "integer", is_nullable => 1 },
  "deleted",
  { data_type => "boolean", is_nullable => 1 },
  "branch",
  { data_type => "text", is_nullable => 1 },
  "owner",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-04-12 14:39:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:k6Hy/1zGYe32H/VJDZ/Hww

__PACKAGE__->has_many(
  "logs_pushes",
  "GitWebAdmin::Schema::LogsPush",
  { "foreign.rid" => "self.id" },
);
__PACKAGE__->has_many(
  "readables",
  "GitWebAdmin::Schema::Readable",
  { "foreign.rid" => "self.id" },
);
__PACKAGE__->belongs_to("forkof", "GitWebAdmin::Schema::Repos", { id => "forkof" });
__PACKAGE__->has_many(
  "repo",
  "GitWebAdmin::Schema::Repos",
  { "foreign.forkof" => "self.id" },
);
__PACKAGE__->belongs_to("owner", "GitWebAdmin::Schema::Users", { id => "owner" });
__PACKAGE__->has_many(
  "repo_tags",
  "GitWebAdmin::Schema::RepoTags",
  { "foreign.rid" => "self.id" },
  {},
);
__PACKAGE__->has_many(
  "subscriptions",
  "GitWebAdmin::Schema::Subscriptions",
  { "foreign.rid" => "self.id" },
);
__PACKAGE__->has_many(
  "writables",
  "GitWebAdmin::Schema::Writable",
  { "foreign.rid" => "self.id" },
);
__PACKAGE__->has_many(
  "branches",
  "GitWebAdmin::Schema::Branches",
  { "foreign.rid" => "self.id" },
);
__PACKAGE__->many_to_many('w_groups' => 'writables', 'gid');
__PACKAGE__->many_to_many('r_groups' => 'readables', 'gid');
__PACKAGE__->many_to_many('subscribers' => 'subscriptions', 'uid');

use GitWebAdmin::Utils qw(json_bool);
sub TO_JSON {
  my ($self) = @_;

  return { id => int($self->id), name => $self->name,
           description => $self->descr,
           owner => $self->owner->uid,
           private => json_bool($self->private),
           tags => [ map { $_->tag } $self->repo_tags ],
  };
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
