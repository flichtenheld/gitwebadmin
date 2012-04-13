package GitWebAdmin::Schema::Keys;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

GitWebAdmin::Schema::Keys

=cut

__PACKAGE__->table("keys");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'keys_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 bits

  data_type: 'integer'
  is_nullable: 0

=head2 type

  data_type: 'ssh_key_type'
  is_nullable: 1
  size: 4

=head2 fingerprint

  data_type: 'text'
  is_nullable: 0

=head2 key

  data_type: 'text'
  is_nullable: 0

=head2 uid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "keys_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "bits",
  { data_type => "integer", is_nullable => 0 },
  "type",
  { data_type => "ssh_key_type", is_nullable => 1, size => 4 },
  "fingerprint",
  { data_type => "text", is_nullable => 0 },
  "key",
  { data_type => "text", is_nullable => 0 },
  "uid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("keys_uid_key1", ["uid", "name"]);
__PACKAGE__->add_unique_constraint("keys_uid_key", ["uid", "key"]);

=head1 RELATIONS

=head2 uid

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Users>

=cut

__PACKAGE__->belongs_to("uid", "GitWebAdmin::Schema::Users", { id => "uid" });


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-03-31 15:57:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qgJmx+hbkOvWrgkPRkR2dw

use GitWebAdmin::Utils qw(json_bool);
sub TO_JSON {
  my ($self) = @_;

  return { id => int($self->id),
           name => $self->name,
           bits => int($self->bits),
           type => $self->type,
           fingerprint => $self->fingerprint
  };
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
