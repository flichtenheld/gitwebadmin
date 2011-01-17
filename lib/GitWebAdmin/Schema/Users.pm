package GitWebAdmin::Schema::Users;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

GitWebAdmin::Schema::Users

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 uid

  data_type: 'text'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 mail

  data_type: 'text'
  is_nullable: 1

=head2 admin

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 active

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 directory

  data_type: 'text'
  default_value: 'local'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "uid",
  { data_type => "text", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "mail",
  { data_type => "text", is_nullable => 1 },
  "admin",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "active",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "directory",
  { data_type => "text", default_value => "local", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("uid");

=head1 RELATIONS

=head2 keys

Type: has_many

Related object: L<GitWebAdmin::Schema::Keys>

=cut

__PACKAGE__->has_many(
  "keys",
  "GitWebAdmin::Schema::Keys",
  { "foreign.uid" => "self.uid" },
  {},
);

=head2 logs_pushes

Type: has_many

Related object: L<GitWebAdmin::Schema::LogsPush>

=cut

__PACKAGE__->has_many(
  "logs_pushes",
  "GitWebAdmin::Schema::LogsPush",
  { "foreign.uid" => "self.uid" },
  {},
);

=head2 members

Type: has_many

Related object: L<GitWebAdmin::Schema::Members>

=cut

__PACKAGE__->has_many(
  "members",
  "GitWebAdmin::Schema::Members",
  { "foreign.uid" => "self.uid" },
  {},
);

=head2 push_acls

Type: has_many

Related object: L<GitWebAdmin::Schema::PushAcl>

=cut

__PACKAGE__->has_many(
  "push_acls",
  "GitWebAdmin::Schema::PushAcl",
  { "foreign.user" => "self.uid" },
  {},
);

=head2 repo

Type: has_many

Related object: L<GitWebAdmin::Schema::Repos>

=cut

__PACKAGE__->has_many(
  "repo",
  "GitWebAdmin::Schema::Repos",
  { "foreign.owner" => "self.uid" },
  {},
);

=head2 subscriptions

Type: has_many

Related object: L<GitWebAdmin::Schema::Subscriptions>

=cut

__PACKAGE__->has_many(
  "subscriptions",
  "GitWebAdmin::Schema::Subscriptions",
  { "foreign.uid" => "self.uid" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-12-29 14:56:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TL8Y1ychaC27bNA/3LDYLA

__PACKAGE__->many_to_many('groups' => 'members', 'gid');
__PACKAGE__->many_to_many('subscribed_repos' => 'subscriptions', 'rid');

use GitWebAdmin::Utils qw(json_bool);
sub TO_JSON {
  my ($self) = @_;

  return { uid => $self->uid,
           name => $self->name,
           mail => $self->mail,
           admin => json_bool($self->admin),
           active => json_bool($self->active),
           groups => [ map { $_->gid } $self->groups ],
  };
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
