package GitWebAdmin::Schema::RepoTriggers;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("repo_triggers");
__PACKAGE__->add_columns(
  "rid",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "tid",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
);
__PACKAGE__->add_unique_constraint("repo_triggers_rid_key", ["rid", "tid"]);
__PACKAGE__->belongs_to(
  "tid",
  "GitWebAdmin::Schema::ExternalTriggers",
  { id => "tid" },
);
__PACKAGE__->belongs_to("rid", "GitWebAdmin::Schema::Repos", { id => "rid" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-07 19:06:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wRV9kdxhryGwdY/vPbsyvw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
