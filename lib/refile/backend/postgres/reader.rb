module Refile
  module Backend
    class Postgres
      class Reader
        PQTRANS_INTRANS = 2 # (idle, within transaction block)

        def initialize(connection, oid)
          @connection = connection
          @oid = oid.to_s.to_i
          @closed = false
          @pos = 0
        end

        attr_reader :connection, :oid, :pos

        def read(length = nil, buffer = nil)
          result = if length
            raise "closed" if @closed
            smart_transaction do |descriptor|
              connection.lo_lseek(descriptor, @pos, PG::SEEK_SET)
              data = connection.lo_read(descriptor, length)
              @pos = connection.lo_tell(descriptor)
              data
            end
          else
            smart_transaction do |descriptor|
              connection.lo_read(descriptor, size)
            end
          end
          buffer.replace(result) if buffer and result
          result
        end

        def eof?
          smart_transaction do |descriptor|
            @pos == size
          end
        end

        def size
          @size ||= smart_transaction do |descriptor|
            current_position = connection.lo_tell(descriptor)
            end_position = connection.lo_lseek(descriptor, 0, PG::SEEK_END)
            connection.lo_lseek(descriptor, current_position, PG::SEEK_SET)
            end_position
          end
        end

        def close
          @closed = true
        end

        private

        def smart_transaction
          result = nil
          ensure_in_transaction do
            begin
              handle = connection.lo_open(oid)
              result = yield handle
              connection.lo_close(handle)
            end
          end
          result
        end

        def ensure_in_transaction
          if connection.transaction_status == PQTRANS_INTRANS
            yield
          else
            connection.transaction do
              yield
            end
          end
        end
      end
    end
  end
end
