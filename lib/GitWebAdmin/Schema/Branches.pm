package GitWebAdmin::Schema::Branches;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("branches");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('branches_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "rid",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "branch",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "commit",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("branches_rid_key", ["rid", "branch"]);
__PACKAGE__->add_unique_constraint("branches_pkey", ["id"]);
__PACKAGE__->belongs_to("rid", "GitWebAdmin::Schema::Repos", { id => "rid" });
__PACKAGE__->has_many(
  "commit_to_branches",
  "GitWebAdmin::Schema::CommitToBranch",
  { "foreign.bid" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-08-18 21:33:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LmeipJifHMT87F+f3Ygacw

__PACKAGE__->many_to_many('commits' => 'commit_to_branches', 'cid');

# You can replace this text with custom content, and it will be preserved on regeneration
1;
