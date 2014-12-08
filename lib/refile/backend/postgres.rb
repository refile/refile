require_relative "./postgres/reader"

module Refile
  module Backend
    class Postgres
      BACKEND_TABLE_NAME = "refile_backend_lo_oids"
      def initialize(connection, max_size: nil, namepace: 'default')
        @connection = connection
        @namespace = namespace
        @max_size = max_size
      end

      def create_backlog_table!
        connection.exec %{
          CREATE TABLE IF NOT EXISTS #{BACKEND_TABLE_NAME}
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

      def ready?
        connection.exec %{
        SELECT count(*) from pg_catalog.pg_tables
        WHERE tablename = '#{BACKEND_TABLE_NAME}';
        } do |result|
          result[0]["count"].to_i > 0
        end
      end

      attr_reader :connection, :namespace

      def upload(uploadable)
        Refile.verify_uploadable(uploadable, @max_size)
        begin
          oid = connection.lo_creat
          connection.transaction do
            begin
              handle = connection.lo_open(oid, PG::INV_WRITE)
              connection.lo_truncate(handle, 0)
              buffer = "" # reuse the same buffer
              until uploadable.eof?
                uploadable.read(Refile.read_chunk_size, buffer)
                connection.lo_write(handle, buffer)
              end
              uploadable.close
              connection.exec %{
                INSERT INTO #{BACKEND_TABLE_NAME} VALUES (#{oid}, '#{namespace}');
              }
              Refile::File.new(self, oid.to_s)
            ensure
              connection.lo_close(handle)
            end
          end
        rescue => error
          raise error
        end
      end

      def open(id)
        Reader.new(connection, id)
      end

      def read(id)
        if exists?(id)
          open(id).read
        else
          nil
        end
      end

      def get(id)
        Refile::File.new(self, id)
      end

      def exists?(id)
        connection.exec %{
          SELECT count(*) FROM #{BACKEND_TABLE_NAME}
          INNER JOIN pg_largeobject
          ON #{BACKEND_TABLE_NAME}.id = pg_largeobject.loid
          WHERE #{BACKEND_TABLE_NAME}.namespace = '#{namespace}'
          AND #{BACKEND_TABLE_NAME}.id = #{id.to_s.to_i};
        } do |result|
          result[0]["count"].to_i > 0
        end
      end

      def size(id)
        if exists?(id)
          open(id).size
        else
          nil
        end
      end

      def delete(id)
        if exists?(id)
          connection.transaction do
            connection.lo_unlink(id.to_s.to_i)
            connection.exec %{DELETE FROM #{BACKEND_TABLE_NAME} WHERE id = #{id.to_s.to_i};}
          end
        end
      end

      def clear!(confirm = nil)
        raise ArgumentError, "are you sure? this will remove all files in the backend, call as `clear!(:confirm)` if you're sure you want to do this" unless confirm == :confirm
        connection.transaction do
          connection.exec %{
            SELECT * FROM #{BACKEND_TABLE_NAME}
            INNER JOIN pg_largeobject ON #{BACKEND_TABLE_NAME}.id = pg_largeobject.loid
            WHERE #{BACKEND_TABLE_NAME}.namespace = '#{namespace}';
          } do |result|
            result.each_row do |row|
              connection.lo_unlink(row[0].to_s.to_i)
            end
          end
          connection.exec %{DELETE FROM #{BACKEND_TABLE_NAME} WHERE namespace = '#{namespace}';}
        end
      end
    end
  end
end
