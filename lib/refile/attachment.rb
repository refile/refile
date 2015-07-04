module Refile
  module Attachment
    # Macro which generates accessors for the given column which make it
    # possible to upload and retrieve previously uploaded files through the
    # generated accessors.
    #
    # The `raise_errors` option controls whether assigning an invalid file
    # should immediately raise an error, or save the error and defer handling
    # it until later.
    #
    # Given a record with an attachment named `image`, the following methods
    # will be added:
    #
    # - `image`
    # - `image=`
    # - `remove_image`
    # - `remove_image=`
    # - `remote_image_url`
    # - `remote_image_url=`
    # - `image_url`
    #
    # @example
    #   class User
    #     extend Refile::Attachment
    #
    #     attachment :image
    #     attr_accessor :image_id
    #   end
    #
    # @param [String] name                              Name of the column which accessor are generated for
    # @param [#to_s] cache                              Name of a backend in {Refile.backends} to use as transient cache
    # @param [#to_s] store                              Name of a backend in {Refile.backends} to use as permanent store
    # @param [true, false] raise_errors                 Whether to raise errors in case an invalid file is assigned
    # @param [Symbol, nil] type                         The type of file that can be uploaded, see {Refile.types}
    # @param [String, Array<String>, nil] extension     Limit the uploaded file to the given extension or list of extensions
    # @param [String, Array<String>, nil] content_type  Limit the uploaded file to the given content type or list of content types
    # @return [void]
    def attachment(name, cache: :cache, store: :store, raise_errors: true, type: nil, extension: nil, content_type: nil)
      definition = AttachmentDefinition.new(name,
        cache: cache,
        store: store,
        raise_errors: raise_errors,
        type: type,
        extension: extension,
        content_type: content_type
      )

      define_singleton_method :"#{name}_attachment_definition" do
        definition
      end

      mod = Module.new do
        attacher = :"#{name}_attacher"

        define_method :"#{name}_attachment_definition" do
          definition
        end

        define_method attacher do
          ivar = :"@#{attacher}"
          instance_variable_get(ivar) or instance_variable_set(ivar, Attacher.new(definition, self))
        end

        define_method "#{name}=" do |value|
          send(attacher).set(value)
        end

        define_method name do
          send(attacher).get
        end

        define_method "remove_#{name}=" do |remove|
          send(attacher).remove = remove
        end

        define_method "remove_#{name}" do
          send(attacher).remove
        end

        define_method "remote_#{name}_url=" do |url|
          send(attacher).download(url)
        end

        define_method "remote_#{name}_url" do
        end

        define_method "#{name}_url" do |*args|
          Refile.attachment_url(self, name, *args)
        end

        define_method "#{name}_data" do
          send(attacher).data
        end

        define_singleton_method("to_s")    { "Refile::Attachment(#{name})" }
        define_singleton_method("inspect") { "Refile::Attachment(#{name})" }
      end

      include mod
    end
  end
end
