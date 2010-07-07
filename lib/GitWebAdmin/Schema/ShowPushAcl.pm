package GitWebAdmin::Schema::ShowPushAcl;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("show_push_acl");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "priority",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
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
  "repository",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
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
    default_value => undef,
    is_nullable => 1,
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


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2010-07-07 12:31:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9R34zzpy0tbCos43plYs3w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
