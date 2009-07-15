package GitWebAdmin::Schema::MantisRepos;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("mantis_repos");
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
  "branches",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-15 14:32:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eVQ0iqT9oSB6As+IsyM4TQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
