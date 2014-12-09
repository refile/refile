require_relative "./postgres/reader"

module Refile
  module Backend
    class Postgres
      DEFAULT_REGISTRY_TABLE = "refile_attachments"
      DEFAULT_NAMESPACE = "default"
      PG_LARGE_OBJECT_TABLE = "pg_largeobject"
      def initialize(connection, max_size: nil, namespace: DEFAULT_NAMESPACE, registry_table: DEFAULT_REGISTRY_TABLE)
        @connection = connection
        @namespace = namespace.to_s
        @registry_table = registry_table
        @max_size = max_size
      end

      attr_reader :connection, :namespace, :registry_table

      def upload(uploadable)
        Refile.verify_uploadable(uploadable, @max_size)
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
            connection.exec_params("INSERT INTO #{registry_table} VALUES ($1::integer, $2::varchar);", [oid, namespace])
            Refile::File.new(self, oid.to_s)
          ensure
            connection.lo_close(handle)
          end
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
        connection.exec_params(%{
          SELECT count(*) FROM #{registry_table}
          INNER JOIN #{PG_LARGE_OBJECT_TABLE}
          ON #{registry_table}.id = #{PG_LARGE_OBJECT_TABLE}.loid
          WHERE #{registry_table}.namespace = $1::varchar
          AND #{registry_table}.id = $2::integer;
        }, [namespace, id.to_s.to_i]) do |result|
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
            connection.exec_params("DELETE FROM #{registry_table} WHERE id = $1::integer;", [id])
          end
        end
      end

      def clear!(confirm = nil)
        raise ArgumentError, "are you sure? this will remove all files in the backend, call as `clear!(:confirm)` if you're sure you want to do this" unless confirm == :confirm
        connection.transaction do
          connection.exec_params(%{
            SELECT * FROM #{registry_table}
            INNER JOIN #{PG_LARGE_OBJECT_TABLE} ON #{registry_table}.id = #{PG_LARGE_OBJECT_TABLE}.loid
            WHERE #{registry_table}.namespace = $1::varchar;
          }, [namespace]) do |result|
            result.each_row do |row|
              connection.lo_unlink(row[0].to_s.to_i)
            end
          end
          connection.exec_params("DELETE FROM #{registry_table} WHERE namespace = $1::varchar;", [namespace])
        end
      end
    end
  end
end
