package GitWebAdmin::Schema::Writable;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("writable");
__PACKAGE__->add_columns(
  "gid",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "rid",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
);
__PACKAGE__->belongs_to("gid", "GitWebAdmin::Schema::Groups", { gid => "gid" });
__PACKAGE__->belongs_to("rid", "GitWebAdmin::Schema::Repos", { id => "rid" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-06-18 22:43:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:E3xAjefk/dAk6+t6EleSZQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
