package GitWebAdmin::Schema::ActiveRepos;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("active_repos");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
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
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "private",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "daemon",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "gitweb",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "owner",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
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
  "deleted",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-08 15:04:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:F9WCMr7V3lNv5VmayfLg+w

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
  "subscriptions",
  "GitWebAdmin::Schema::Subscriptions",
  { "foreign.rid" => "self.id" },
);
__PACKAGE__->has_many(
  "writables",
  "GitWebAdmin::Schema::Writable",
  { "foreign.rid" => "self.id" },
);
__PACKAGE__->many_to_many('w_groups' => 'writables', 'gid');
__PACKAGE__->many_to_many('r_groups' => 'readables', 'gid');
__PACKAGE__->many_to_many('subscribers' => 'subscriptions', 'uid');

# You can replace this text with custom content, and it will be preserved on regeneration
1;
