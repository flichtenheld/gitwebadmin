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


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-08-18 21:33:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:il2mlIWtfc2CKn0Z8mxJ8w

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("repos_pkey", ["id"]);
__PACKAGE__->add_unique_constraint("repos_name_key", ["name"]);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
