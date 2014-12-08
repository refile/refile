require "refile"
require "mini_magick"

module Refile
  class ImageProcessor
    def initialize(method)
      @method = method
    end

    def convert(img, format)
      img.format(format.to_s.downcase)
    end

    def limit(img, width, height)
      img.resize "#{width}x#{height}>"
    end

    def fit(img, width, height)
      img.resize "#{width}x#{height}"
    end

    def fill(img, width, height, gravity = 'Center')
      width = width.to_i
      height = height.to_i
      cols, rows = img[:dimensions]
      img.combine_options do |cmd|
        if width != cols || height != rows
          scale_x = width/cols.to_f
          scale_y = height/rows.to_f
          if scale_x >= scale_y
            cols = (scale_x * (cols + 0.5)).round
            rows = (scale_x * (rows + 0.5)).round
            cmd.resize "#{cols}"
          else
            cols = (scale_y * (cols + 0.5)).round
            rows = (scale_y * (rows + 0.5)).round
            cmd.resize "x#{rows}"
          end
        end
        cmd.gravity gravity
        cmd.background "rgba(255,255,255,0.0)"
        cmd.extent "#{width}x#{height}" if cols != width || rows != height
      end
    end

    def pad(img, width, height, background = "transparent", gravity = "Center")
      img.combine_options do |cmd|
        cmd.thumbnail "#{width}x#{height}>"
        if background == "transparent"
          cmd.background "rgba(255, 255, 255, 0.0)"
        else
          cmd.background background
        end
        cmd.gravity gravity
        cmd.extent "#{width}x#{height}"
      end
    end

    def call(file, *args, format: nil)
      path = file.download.path
      img = ::MiniMagick::Image.open(path)
      img.format(format.to_s.downcase) if format
      send(@method, img, *args)

      img.write(path)

      ::File.open(path, "rb")
    end
  end
end

[:fill, :fit, :limit, :pad, :convert].each do |name|
  Refile.processor(name, Refile::ImageProcessor.new(name))
end
