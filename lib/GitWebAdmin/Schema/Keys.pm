package GitWebAdmin::Schema::Keys;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("keys");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('keys_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "uid",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "bits",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "type",
  {
    data_type => "ssh_key_type",
    default_value => undef,
    is_nullable => 1,
    size => 4,
  },
  "fingerprint",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "key",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("keys_uid_key1", ["uid", "name"]);
__PACKAGE__->add_unique_constraint("keys_pkey", ["id"]);
__PACKAGE__->add_unique_constraint("keys_uid_key", ["uid", "key"]);
__PACKAGE__->belongs_to("uid", "GitWebAdmin::Schema::Users", { uid => "uid" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-02 12:19:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VHcPaulzKqRaxZUF6j+xHQ

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
