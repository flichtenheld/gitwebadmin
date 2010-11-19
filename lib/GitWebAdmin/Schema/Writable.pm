package GitWebAdmin::Schema::Writable;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

GitWebAdmin::Schema::Writable

=cut

__PACKAGE__->table("writable");

=head1 ACCESSORS

=head2 gid

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 rid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "gid",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "rid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("gid", "rid");

=head1 RELATIONS

=head2 gid

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Groups>

=cut

__PACKAGE__->belongs_to("gid", "GitWebAdmin::Schema::Groups", { gid => "gid" });

=head2 rid

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Repos>

=cut

__PACKAGE__->belongs_to("rid", "GitWebAdmin::Schema::Repos", { id => "rid" });


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-11-19 19:11:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:E5xuWEdt7vAfIdCv6IcDTg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
