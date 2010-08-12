package GitWebAdmin::Schema::Subscriptions;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

GitWebAdmin::Schema::Subscriptions

=cut

__PACKAGE__->table("subscriptions");

=head1 ACCESSORS

=head2 rid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 uid

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "rid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "uid",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->add_unique_constraint("subscriptions_rid_key", ["rid", "uid"]);

=head1 RELATIONS

=head2 uid

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Users>

=cut

__PACKAGE__->belongs_to("uid", "GitWebAdmin::Schema::Users", { uid => "uid" });

=head2 rid

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Repos>

=cut

__PACKAGE__->belongs_to("rid", "GitWebAdmin::Schema::Repos", { id => "rid" });


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-08-12 17:07:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hsqRTL+5qfkswOJptzLq8A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
