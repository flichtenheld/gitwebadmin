package GitWebAdmin::Schema::Members;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("members");
__PACKAGE__->add_columns(
  "uid",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "gid",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->add_unique_constraint("members_uid_key", ["uid", "gid"]);
__PACKAGE__->belongs_to("uid", "GitWebAdmin::Schema::Users", { uid => "uid" });
__PACKAGE__->belongs_to("gid", "GitWebAdmin::Schema::Groups", { gid => "gid" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-06-23 15:27:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KPSarn2OY1CYOZNVgWJfRA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
