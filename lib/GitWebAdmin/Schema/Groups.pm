package GitWebAdmin::Schema::Groups;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("groups");
__PACKAGE__->add_columns(
  "gid",
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
);
__PACKAGE__->set_primary_key("gid");
__PACKAGE__->add_unique_constraint("groups_pkey", ["gid"]);
__PACKAGE__->has_many(
  "members",
  "GitWebAdmin::Schema::Members",
  { "foreign.gid" => "self.gid" },
);
__PACKAGE__->has_many(
  "push_acls",
  "GitWebAdmin::Schema::PushAcl",
  { "foreign.group" => "self.gid" },
);
__PACKAGE__->has_many(
  "readables",
  "GitWebAdmin::Schema::Readable",
  { "foreign.gid" => "self.gid" },
);
__PACKAGE__->has_many(
  "writables",
  "GitWebAdmin::Schema::Writable",
  { "foreign.gid" => "self.gid" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-01-11 22:33:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yMKv5KtQZ+xx68FeNrmpmw

__PACKAGE__->many_to_many('users' => 'members', 'uid');
__PACKAGE__->many_to_many('w_repos' => 'writables', 'rid');
__PACKAGE__->many_to_many('r_repos' => 'readables', 'rid');

use GitWebAdmin::Utils qw(json_bool);
sub TO_JSON {
  my ($self) = @_;

  return { gid => $self->gid,
           name => $self->name,
           members => [ map { $_->uid } $self->users ],
           write_access => [ map { $_->name } $self->w_repos ],
           read_access  => [ map { $_->name } $self->r_repos ],
  };
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
