require "open-uri"
require "forwardable"
require "cgi"

module Refile
  # This class downloads a given URL and returns its IO, size, content type and
  # original file name.
  #
  # Usage:
  #
  #     download = Refile::Download.new('http://example.com/my/data.bin')
  #     download.io
  #     #=> #<StringIO:0x00007fdcb3932fc8 ...>
  #     download.size
  #     #=> 389620
  #     download.content_type
  #     #=> "application/octet-stream"
  #     download.original_file_name
  #     #=> "data.bin"
  class Download
    OPTIONS = {
      "User-Agent" => "Refile/#{Refile::VERSION}",
      open_timeout: 30,
      read_timeout: 30,
      redirect: false
    }.freeze

    extend Forwardable
    def_delegators :@io, :size, :content_type

    attr_reader :io, :original_filename

    def initialize(uri)
      @io = download(uri)
      @original_filename = extract_original_filename
    end

  private

    def download(uri)
      uri = ensure_uri(uri)
      follows_remaining = 10

      begin
        uri.open(OPTIONS)
      rescue OpenURI::HTTPRedirect => exception
        raise Refile::TooManyRedirects if follows_remaining.zero?

        uri = ensure_uri(exception.uri)
        follows_remaining -= 1

        retry
      rescue OpenURI::HTTPError => exception
        if exception.message.include?("(Invalid Location URI)")
          raise Refile::InvalidUrl, "Invalid Redirect URI: #{response["Location"]}"
        end

        raise exception
      end
    end

    def ensure_uri(url)
      begin
        uri = URI(url)
      rescue URI::InvalidURIError
        raise Refile::InvalidUrl, "Invalid URI: #{uri.inspect}"
      end

      unless uri.is_a?(URI::HTTP)
        raise Refile::InvalidUrl, "URL scheme needs to be http or https: #{uri}"
      end

      uri
    end

    def extract_original_filename
      filename_from_content_disposition || filename_from_path
    end

    def filename_from_content_disposition
      content_disposition = @io.meta["content-disposition"].to_s

      escaped_filename =
        content_disposition[/filename\*=UTF-8''(\S+)/, 1] ||
        content_disposition[/filename="([^"]*)"/, 1] ||
        content_disposition[/filename=(\S+)/, 1]

      filename = CGI.unescape(escaped_filename.to_s)

      filename unless filename.empty?
    end

    def filename_from_path
      filename = @io.base_uri.path.split("/").last
      CGI.unescape(filename) if filename
    end
  end
end
