package GitWebAdmin::Schema::Repos;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("repos");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('repos_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "descr",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "branch",
  {
    data_type => "text",
    default_value => "'master'::text",
    is_nullable => 0,
    size => undef,
  },
  "private",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "daemon",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "gitweb",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "mantis",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "owner",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "forkof",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "mirrorof",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "mirrorupd",
  { data_type => "integer", default_value => 86400, is_nullable => 1, size => 4 },
  "deleted",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("repos_pkey", ["id"]);
__PACKAGE__->add_unique_constraint("repos_name_key", ["name"]);
__PACKAGE__->has_many(
  "branches",
  "GitWebAdmin::Schema::Branches",
  { "foreign.rid" => "self.id" },
);
__PACKAGE__->has_many(
  "commits",
  "GitWebAdmin::Schema::Commits",
  { "foreign.rid" => "self.id" },
);
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
__PACKAGE__->belongs_to("owner", "GitWebAdmin::Schema::Users", { uid => "owner" });
__PACKAGE__->has_many(
  "repo_triggers",
  "GitWebAdmin::Schema::RepoTriggers",
  { "foreign.rid" => "self.id" },
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


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-07 19:06:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AZ8bfJfwr2kHN7bhk8Q9lA

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
