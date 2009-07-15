package GitWebAdmin::Schema::CommitToBranch;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("commit_to_branch");
__PACKAGE__->add_columns(
  "cid",
  { data_type => "bigint", default_value => undef, is_nullable => 0, size => 8 },
  "bid",
  { data_type => "bigint", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->add_unique_constraint("commit_to_branch_cid_key", ["cid", "bid"]);
__PACKAGE__->belongs_to("bid", "GitWebAdmin::Schema::Branches", { id => "bid" });
__PACKAGE__->belongs_to("cid", "GitWebAdmin::Schema::Commits", { id => "cid" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-15 14:32:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6mSq6UBjuYr3BFvb7IqlJA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
