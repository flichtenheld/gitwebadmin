package GitWebAdmin::Schema::RepoTriggers;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

GitWebAdmin::Schema::RepoTriggers

=cut

__PACKAGE__->table("repo_triggers");

=head1 ACCESSORS

=head2 rid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 tid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "rid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "tid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("rid", "tid");

=head1 RELATIONS

=head2 tid

Type: belongs_to

Related object: L<GitWebAdmin::Schema::ExternalTriggers>

=cut

__PACKAGE__->belongs_to(
  "tid",
  "GitWebAdmin::Schema::ExternalTriggers",
  { id => "tid" },
);

=head2 rid

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Repos>

=cut

__PACKAGE__->belongs_to("rid", "GitWebAdmin::Schema::Repos", { id => "rid" });


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-11-19 19:11:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eSgFQ7TEx4B/kz52ftMqyA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
