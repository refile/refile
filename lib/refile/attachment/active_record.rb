module Refile
  module ActiveRecord
    module Attachment
      include Refile::Attachment

      # Attachment method which hooks into ActiveRecord models
      #
      # @see Refile::Attachment#attachment
      def attachment(name, raise_errors: false, **options)
        super

        attacher = "#{name}_attacher"

        validate do
          if send(attacher).present?
            send(attacher).valid?
            errors = send(attacher).errors
            errors.each do |error|
              self.errors.add(name, error)
            end
          end
        end

        define_method "#{name}=" do |value|
          send("#{name}_id_will_change!")
          super(value)
        end

        before_save do
          send(attacher).store!
        end

        after_destroy do
          send(attacher).delete!
        end
      end

      # @ignore
      #   rubocop:disable Metrics/MethodLength
      def accepts_attachments_for(association_name, attachment: :file)
        association = reflect_on_association(association_name)
        name = "#{association_name}_#{attachment.to_s.pluralize}"

        mod = Module.new do
          define_method :"#{name}_attachment_definition" do
            association.klass.send("#{attachment}_attachment_definition")
          end

          define_method :"#{name}_data" do
            if send(association_name).all? { |record| record.send("#{attachment}_attacher").valid? }
              send(association_name).map(&:"#{attachment}_data")
            end
          end

          define_method :"#{name}" do
            send(association_name).map(&attachment)
          end

          define_method :"#{name}=" do |files|
            cache = begin
              JSON.parse(files.first)
            rescue JSON::ParserError
            end
            files = files.drop(1)
            if files.empty? and cache.present?
              cache.select(&:present?).each do |file|
                send(association_name).build(attachment => file.to_json)
              end
            else
              files.select(&:present?).each do |file|
                send(association_name).build(attachment => file)
              end
            end
          end
        end

        include mod
      end
    end
  end
end

::ActiveRecord::Base.extend(Refile::ActiveRecord::Attachment)
