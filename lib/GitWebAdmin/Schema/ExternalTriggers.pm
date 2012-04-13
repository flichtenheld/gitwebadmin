package GitWebAdmin::Schema::ExternalTriggers;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

GitWebAdmin::Schema::ExternalTriggers

=cut

__PACKAGE__->table("external_triggers");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'external_triggers_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 method

  data_type: 'text'
  default_value: 'ssh'
  is_nullable: 0

=head2 uri

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "external_triggers_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "method",
  { data_type => "text", default_value => "ssh", is_nullable => 0 },
  "uri",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("external_triggers_name_key", ["name"]);
__PACKAGE__->add_unique_constraint("external_triggers_uri_key", ["uri"]);

=head1 RELATIONS

=head2 repo_triggers

Type: has_many

Related object: L<GitWebAdmin::Schema::RepoTriggers>

=cut

__PACKAGE__->has_many(
  "repo_triggers",
  "GitWebAdmin::Schema::RepoTriggers",
  { "foreign.tid" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-03-31 15:57:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WgKcRJjykFtjqtk5gfdaYw

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
