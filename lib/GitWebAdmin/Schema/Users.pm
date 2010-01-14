package GitWebAdmin::Schema::Users;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("users");
__PACKAGE__->add_columns(
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
    is_nullable => 1,
    size => undef,
  },
  "mail",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "admin",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "active",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 0,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("uid");
__PACKAGE__->add_unique_constraint("users_pkey", ["uid"]);
__PACKAGE__->has_many(
  "keys",
  "GitWebAdmin::Schema::Keys",
  { "foreign.uid" => "self.uid" },
);
__PACKAGE__->has_many(
  "logs_pushes",
  "GitWebAdmin::Schema::LogsPush",
  { "foreign.uid" => "self.uid" },
);
__PACKAGE__->has_many(
  "members",
  "GitWebAdmin::Schema::Members",
  { "foreign.uid" => "self.uid" },
);
__PACKAGE__->has_many(
  "push_acls",
  "GitWebAdmin::Schema::PushAcl",
  { "foreign.user" => "self.uid" },
);
__PACKAGE__->has_many(
  "repo",
  "GitWebAdmin::Schema::Repos",
  { "foreign.owner" => "self.uid" },
);
__PACKAGE__->has_many(
  "subscriptions",
  "GitWebAdmin::Schema::Subscriptions",
  { "foreign.uid" => "self.uid" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-01-11 22:33:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qU4eTC8k0nCF+AzohnDxZw

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
