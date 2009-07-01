package GitWebAdmin::Schema::LogsPush;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("logs_push");
__PACKAGE__->add_columns(
  "rid",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "uid",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "date",
  {
    data_type => "timestamp without time zone",
    default_value => "now()",
    is_nullable => 0,
    size => 8,
  },
  "old_id",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "new_id",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "ref",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "notified",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
);
__PACKAGE__->belongs_to("rid", "GitWebAdmin::Schema::Repos", { id => "rid" });
__PACKAGE__->belongs_to("uid", "GitWebAdmin::Schema::Users", { uid => "uid" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-01 11:07:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+6Z5qkFJDtxtVA8jV0rZmw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
