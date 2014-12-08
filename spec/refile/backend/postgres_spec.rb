if ENV["PG"]
  require "refile/backend/postgres"
  require 'pg'

  RSpec.describe Refile::Backend::Postgres do
    before(:all) { @db_connection =  PG.connect( dbname: 'refile_test' ) }
    before(:each) { @db_connection.exec %{ DROP TABLE IF EXISTS #{Refile::Backend::Postgres::BACKEND_TABLE_NAME}; } }
    let(:backend) { Refile::Backend::Postgres.new(@db_connection, max_size: 100) }

    describe "when backend table has not been created" do
      it "should not be ready" do
        expect(backend.ready?).to be_falsy
      end

      it "should be ready when #create_backlog_table! executed" do
        backend.create_backlog_table!
        expect(backend.ready?).to be_truthy
      end
    end

    describe "when backend table has been created" do
      let(:backend) do
        old = super()
        old.create_backlog_table!
        old
      end
      it_behaves_like :backend
    end
  end
end
