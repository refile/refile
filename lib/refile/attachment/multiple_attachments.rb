module Refile
  module Attachment
    # Builds a module to be used by "accepts_attachments_for"
    #
    # @api private
    module MultipleAttachments
      def self.new(collection_name, collection_class:, name:, attachment:, append:, &block)
        Module.new do
          define_method :"#{name}_attachment_definition" do
            collection_class.send("#{attachment}_attachment_definition")
          end

          define_method :"#{name}_data" do
            collection = send(collection_name)

            all_attachers_valid = collection.all? do |record|
              record.send("#{attachment}_attacher").valid?
            end

            collection.map(&:"#{attachment}_data") if all_attachers_valid
          end

          define_method :"#{name}" do
            send(collection_name).map(&attachment)
          end

          define_method :"#{name}=" do |files|
            cache, files = [files].flatten.partition { |file| file.is_a?(String) }
            cache = Refile.parse_json(cache.first) || []
            cache = cache.reject(&:empty?)
            files = files.compact

            if not append and (!files.empty? or !cache.empty?)
              send("#{collection_name}=", [])
            end

            collection = send(collection_name)

            if files.empty? and !cache.empty?
              cache.each do |file|
                collection << collection_class.new(attachment => file.to_json)
              end
            else
              files.each do |file|
                collection << collection_class.new(attachment => file)
              end
            end
          end
          module_eval(&block) if block_given?
        end
      end
    end
  end
end
