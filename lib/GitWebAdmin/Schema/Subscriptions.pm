package GitWebAdmin::Schema::Subscriptions;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("subscriptions");
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
);
__PACKAGE__->add_unique_constraint("subscriptions_rid_key", ["rid", "uid"]);
__PACKAGE__->belongs_to("uid", "GitWebAdmin::Schema::Users", { uid => "uid" });
__PACKAGE__->belongs_to("rid", "GitWebAdmin::Schema::Repos", { id => "rid" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-06-30 10:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CGnsw0BGjzOMOjxJVM3pGg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
