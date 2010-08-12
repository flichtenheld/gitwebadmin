package GitWebAdmin::Schema::Members;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

GitWebAdmin::Schema::Members

=cut

__PACKAGE__->table("members");

=head1 ACCESSORS

=head2 uid

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 gid

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "uid",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "gid",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->add_unique_constraint("members_uid_key", ["uid", "gid"]);

=head1 RELATIONS

=head2 uid

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Users>

=cut

__PACKAGE__->belongs_to("uid", "GitWebAdmin::Schema::Users", { uid => "uid" });

=head2 gid

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Groups>

=cut

__PACKAGE__->belongs_to("gid", "GitWebAdmin::Schema::Groups", { gid => "gid" });


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-08-12 17:07:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ETfWhz+1slJV4dGhcRLafQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
