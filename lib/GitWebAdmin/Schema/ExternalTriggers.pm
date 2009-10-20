package GitWebAdmin::Schema::ExternalTriggers;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("external_triggers");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('external_triggers_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "method",
  {
    data_type => "trigger_method_type",
    default_value => "'ssh'::trigger_method_type",
    is_nullable => 0,
    size => 4,
  },
  "uri",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("external_triggers_name_key", ["name"]);
__PACKAGE__->add_unique_constraint("external_triggers_pkey", ["id"]);
__PACKAGE__->add_unique_constraint("external_triggers_uri_key", ["uri"]);
__PACKAGE__->has_many(
  "repo_triggers",
  "GitWebAdmin::Schema::RepoTriggers",
  { "foreign.tid" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-07 19:06:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:abp8nC01HQDBaKessSBzIw

__PACKAGE__->many_to_many('repos' => 'repo_triggers', 'rid');

sub TO_JSON {
  my ($self) = @_;

  return { id => $self->id,
           name => $self->name,
           method => $self->method, uri => $self->uri,
           repos => [ map { $_->name } $self->repos ],
  };
}


# You can replace this text with custom content, and it will be preserved on regeneration
1;
