package GitWebAdmin::Schema::Branches;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

GitWebAdmin::Schema::Branches

=cut

__PACKAGE__->table("branches");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'branches_id_seq'

=head2 rid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 branch

  data_type: 'text'
  is_nullable: 0

=head2 commit

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "branches_id_seq",
  },
  "rid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "branch",
  { data_type => "text", is_nullable => 0 },
  "commit",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("branches_rid_key", ["rid", "branch"]);

=head1 RELATIONS

=head2 rid

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Repos>

=cut

__PACKAGE__->belongs_to("rid", "GitWebAdmin::Schema::Repos", { id => "rid" });


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-10 18:32:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bSyebEtU4wrhhRL9C9Sf0w

# You can replace this text with custom content, and it will be preserved on regeneration
1;
