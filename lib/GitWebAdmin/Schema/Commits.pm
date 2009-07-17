package GitWebAdmin::Schema::Commits;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("commits");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "bigint",
    default_value => "nextval('commits_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "rid",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "commit",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("commits_rid_key", ["rid", "commit"]);
__PACKAGE__->add_unique_constraint("commits_pkey", ["id"]);
__PACKAGE__->belongs_to("rid", "GitWebAdmin::Schema::Repos", { id => "rid" });
__PACKAGE__->has_many(
  "commit_to_branches",
  "GitWebAdmin::Schema::CommitToBranch",
  { "foreign.cid" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-15 14:32:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dXWoagN8sUrvv/uNzfmlGw

__PACKAGE__->many_to_many('branches' => 'commit_to_branches', 'bid');

# You can replace this text with custom content, and it will be preserved on regeneration
1;
