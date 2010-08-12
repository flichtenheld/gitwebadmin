package GitWebAdmin::Schema::MantisRepos;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

GitWebAdmin::Schema::MantisRepos

=cut

__PACKAGE__->table("mantis_repos");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 descr

  data_type: 'text'
  is_nullable: 1

=head2 branches

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "descr",
  { data_type => "text", is_nullable => 1 },
  "branches",
  { data_type => "text", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-08-12 17:07:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e5F6Xwmdu26rcZnA7fBHiA

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("repos_pkey", ["id"]);
__PACKAGE__->add_unique_constraint("repos_name_key", ["name"]);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
