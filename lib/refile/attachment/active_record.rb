module Refile
  module ActiveRecord
    module Attachment
      include Refile::Attachment

      # Attachment method which hooks into ActiveRecord models
      #
      # @return [void]
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

        define_method "remove_#{name}=" do |value|
          send("#{name}_id_will_change!")
          super(value)
        end

        define_method "remote_#{name}_url=" do |value|
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

      # Macro which generates accessors for assigning multiple attachments at
      # once. This is primarily useful together with multiple file uploads.
      #
      # The name of the generated accessors will be the name of the association
      # and the name of the attachment in the associated model. So if a `Post`
      # accepts attachments for `images`, and the attachment in the `Image`
      # model is named `file`, then the accessors will be named `images_files`.
      #
      # @example in model
      #   class Post
      #     has_many :images, dependent: :destroy
      #     accepts_attachments_for :images
      #   end
      #
      # @example in associated model
      #   class Image
      #     attachment :image
      #   end
      #
      # @example in form
      #   <%= form_for @post do |form| %>
      #     <%= form.attachment_field :images_files, multiple: true %>
      #   <% end %>
      #
      # @param [Symbol] association_name     Name of the association
      # @param [Symbol] attachment           Name of the attachment in the associated model
      # @param [Symbol] append               If true, new files are appended instead of replacing the entire list of associated models.
      # @return [void]
      def accepts_attachments_for(association_name, attachment: :file, append: false)
        association = reflect_on_association(association_name)
        name = "#{association_name}_#{attachment.to_s.pluralize}"

        mod = Module.new do
          define_method :"#{name}_attachment_definition" do
            association.klass.send("#{attachment}_attachment_definition")
          end

          define_method :"#{name}_data" do
            if send(association_name).all? { |record| record.send("#{attachment}_attacher").valid? }
              send(association_name).map(&:"#{attachment}_data").select(&:present?)
            end
          end

          define_method :"#{name}" do
            send(association_name).map(&attachment)
          end

          define_method :"#{name}=" do |files|
            cache, files = files.partition { |file| file.is_a?(String) }

            cache = Refile.parse_json(cache.first)

            if not append and (files.present? or cache.present?)
              send("#{association_name}=", [])
            end

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
