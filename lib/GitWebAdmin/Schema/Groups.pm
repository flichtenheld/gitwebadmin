package GitWebAdmin::Schema::Groups;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

GitWebAdmin::Schema::Groups

=cut

__PACKAGE__->table("groups");

=head1 ACCESSORS

=head2 gid

  data_type: 'text'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 descr

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "gid",
  { data_type => "text", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "descr",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("gid");

=head1 RELATIONS

=head2 members

Type: has_many

Related object: L<GitWebAdmin::Schema::Members>

=cut

__PACKAGE__->has_many(
  "members",
  "GitWebAdmin::Schema::Members",
  { "foreign.gid" => "self.gid" },
  {},
);

=head2 push_acls

Type: has_many

Related object: L<GitWebAdmin::Schema::PushAcl>

=cut

__PACKAGE__->has_many(
  "push_acls",
  "GitWebAdmin::Schema::PushAcl",
  { "foreign.group" => "self.gid" },
  {},
);

=head2 readables

Type: has_many

Related object: L<GitWebAdmin::Schema::Readable>

=cut

__PACKAGE__->has_many(
  "readables",
  "GitWebAdmin::Schema::Readable",
  { "foreign.gid" => "self.gid" },
  {},
);

=head2 writables

Type: has_many

Related object: L<GitWebAdmin::Schema::Writable>

=cut

__PACKAGE__->has_many(
  "writables",
  "GitWebAdmin::Schema::Writable",
  { "foreign.gid" => "self.gid" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-08-12 17:07:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Hl6XJAA5E8b+B4Ao2BtGfQ

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
