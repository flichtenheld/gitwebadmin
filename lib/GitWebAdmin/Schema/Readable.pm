package GitWebAdmin::Schema::Readable;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

GitWebAdmin::Schema::Readable

=cut

__PACKAGE__->table("readable");

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

=head2 rid

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Repos>

=cut

__PACKAGE__->belongs_to("rid", "GitWebAdmin::Schema::Repos", { id => "rid" });

=head2 gid

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Groups>

=cut

__PACKAGE__->belongs_to("gid", "GitWebAdmin::Schema::Groups", { gid => "gid" });


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-10 18:32:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yyLUPfrBHgqui2He0od4Sw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
