if ENV["PG"]
  require "refile/backend/postgres"
  require 'pg'

  RSpec.describe Refile::Backend::Postgres do
    before(:all) do
      @db_connection = PG.connect( dbname: 'refile_test' )
      @db_connection.exec %{ DROP TABLE IF EXISTS #{Refile::Backend::Postgres::DEFAULT_REGISTRY_TABLE} CASCADE; }
      @db_connection.exec %{
        CREATE TABLE IF NOT EXISTS #{Refile::Backend::Postgres::DEFAULT_REGISTRY_TABLE}
        (
          id serial NOT NULL,
          namespace character varying(255),
          CONSTRAINT refile_backend_lo_oids_pkey PRIMARY KEY (id)
        )
        WITH(
          OIDS=FALSE
        );
      }
    end
    let(:backend) { Refile::Backend::Postgres.new(@db_connection, max_size: 100) }

    it_behaves_like :backend
  end
end
