# encoding: utf-8

require "refile/spec_helper"
require "refile/image_processing"

describe Refile::ImageProcessor do
  before do
    @image_processor = described_class.new(:convert)
    @minimagic_image = MiniMagick::Image.open(path("portrait.jpg"))
  end

  describe "#convert" do
    it "should convert from one file format to another" do
      converted_image = @image_processor.convert(@minimagic_image, "png")
      expect(converted_image["format"]).to match(/PNG/)
      expect(File.extname(converted_image.path)).to match(/png/)
    end

    it "should convert all pages when no page number is specified" do
      expect_any_instance_of(MiniMagick::Image).to receive(:format).with("png").once
      @image_processor.convert(@minimagic_image, "png")
    end
  end

  describe "#limit" do
    it "should resize the image to fit within the given dimensions and maintain file type" do
      limited_image = @image_processor.limit(@minimagic_image, 200, 200)
      expect(limited_image.width).to be(144)
      expect(limited_image.height).to be(200)
      expect(limited_image["format"]).to match(/JPEG/)
      expect(File.extname(limited_image.path)).to match(/jpg/)
    end

    it "should resize the image to fit within the given dimensions and maintain updated file type" do
      converted_image = @image_processor.convert(@minimagic_image, "png")
      converted_and_limited_image = @image_processor.limit(converted_image, 200, 200)
      expect(converted_and_limited_image.width).to be(144)
      expect(converted_and_limited_image.height).to be(200)
      expect(converted_and_limited_image["format"]).to match(/PNG/)
      expect(File.extname(converted_and_limited_image.path)).to match(/png/)
    end

    it "should not scale up the image if it smaller than the given dimensions" do
      limited_image = @image_processor.limit(@minimagic_image, 1000, 1000)
      expect(limited_image.width).to be(500)
      expect(limited_image.height).to be(695)
    end
  end

  describe "#fit" do
    it "should resize the image to fit within the given dimensions and maintain file type" do
      fitted_image = @image_processor.fit(@minimagic_image, 200, 200)
      expect(fitted_image.width).to be(144)
      expect(fitted_image.height).to be(200)
      expect(fitted_image["format"]).to match(/JPEG/)
    end

    it "should resize the image to fit within the given dimensions and maintain updated file type" do
      converted_image = @image_processor.convert(@minimagic_image, "png")
      converted_and_fitted_image = @image_processor.fit(converted_image, 200, 200)
      expect(converted_and_fitted_image.width).to be(144)
      expect(converted_and_fitted_image.height).to be(200)
      expect(converted_and_fitted_image["format"]).to match(/PNG/)
      expect(File.extname(converted_and_fitted_image.path)).to match(/png/)
    end

    it "should scale up the image if it smaller than the given dimensions" do
      fitted_image = @image_processor.fit(@minimagic_image, 1000, 1000)
      expect(fitted_image.width).to be(719)
      expect(fitted_image.height).to be(1000)
    end
  end

  describe "#fill" do
    it "should resize the image to exactly the given dimensions and maintain file type" do
      filled_image = @image_processor.fill(@minimagic_image, 200, 200)
      expect(filled_image.width).to be(200)
      expect(filled_image.height).to be(200)
      expect(filled_image["format"]).to match(/JPEG/)
    end

    it "should resize the image to exactly the given dimensions and maintain updated file type" do
      converted_image = @image_processor.convert(@minimagic_image, "png")
      filled_and_converted_image = @image_processor.fill(converted_image, 200, 200)
      expect(filled_and_converted_image.width).to be(200)
      expect(filled_and_converted_image.height).to be(200)
      expect(filled_and_converted_image["format"]).to match(/PNG/)
      expect(File.extname(filled_and_converted_image.path)).to match(/png/)
    end

    it "should scale up the image if it smaller than the given dimensions" do
      filled_image = @image_processor.fill(@minimagic_image, 1000, 1000)
      expect(filled_image.width).to be(1000)
      expect(filled_image.height).to be(1000)
    end
  end

  describe "#pad" do
    it "should resize the image to exactly the given dimensions and maintain file type" do
      padded_image = @image_processor.pad(@minimagic_image, 200, 200)
      expect(padded_image.width).to be(200)
      expect(padded_image.height).to be(200)
      expect(padded_image["format"]).to match(/JPEG/)
    end

    it "should resize the image to exactly the given dimensions and maintain updated file type" do
      converted_image = @image_processor.convert(@minimagic_image, "png")
      converted_and_padded_image = @image_processor.pad(converted_image, 200, 200)
      expect(converted_and_padded_image.width).to be(200)
      expect(converted_and_padded_image.height).to be(200)
      expect(converted_and_padded_image["format"]).to match(/PNG/)
    end

    it "should scale up the image if it smaller than the given dimensions" do
      padded_image = @image_processor.pad(@minimagic_image, 1000, 1000)
      expect(padded_image.width).to be(1000)
      expect(padded_image.height).to be(1000)
    end

    it "should pad with white" do
      padded_image = @image_processor.pad(@minimagic_image, 200, 200)
      color = color_of_pixel(padded_image.path, 0, 0)
      expect(color).to include("#FFFFFF")
      expect(color).not_to include("#FFFFFF00")
    end

    it "should pad with transparent" do
      converted_image = @image_processor.convert(@minimagic_image, "png")
      converted_and_padded_image = @image_processor.pad(converted_image, 200, 200, "transparent")
      color = color_of_pixel(converted_and_padded_image.path, 0, 0)
      expect(color).to include("#FFFFFF00")
    end

    it "should not pad with transparent" do
      padded_image = @image_processor.pad(@minimagic_image, 200, 200, "transparent")
      padded_and_converted_image = @image_processor.convert(padded_image, "png")
      color = color_of_pixel(padded_and_converted_image.path, 0, 0)
      expect(color).to include("#FFFFFF")
      expect(color).not_to include("#FFFFFF00")
    end
  end

  describe "#call" do
    it "should convert from one file format to another" do
      @image_processor = described_class.new(:convert)
      converted_image = @image_processor.call(@minimagic_image, "png")
      expect(File.extname(converted_image)).to match(/png/)
    end

    it "should resize the image to fit within the given dimensions and maintain file type" do
      @image_processor = described_class.new(:limit)
      limited_image = @image_processor.call(@minimagic_image, 200, 200)
      limited_image = MiniMagick::Image.open(limited_image.path)
      expect(limited_image.width).to be(144)
      expect(limited_image.height).to be(200)
      expect(limited_image["format"]).to match(/JPEG/)
      expect(File.extname(limited_image.path)).to match(/jpg/)
    end

    it "should resize the image to fit within the given dimensions and maintain updated file type" do
      @image_processor = described_class.new(:fit)
      fitted_image = @image_processor.call(@minimagic_image, 200, 200, format: :png)
      fitted_image = MiniMagick::Image.open(fitted_image.path)
      expect(fitted_image.width).to be(144)
      expect(fitted_image.height).to be(200)
      expect(fitted_image["format"]).to match(/PNG/)
      expect(File.extname(fitted_image.path)).to match(/png/)
    end

    it "should resize the image to exactly the given dimensions and maintain file type" do
      @image_processor = described_class.new(:fill)
      filled_image = @image_processor.call(@minimagic_image, 200, 200)
      filled_image = MiniMagick::Image.open(filled_image.path)
      expect(filled_image.width).to be(200)
      expect(filled_image.height).to be(200)
      expect(filled_image["format"]).to match(/JPEG/)
      expect(File.extname(filled_image.path)).to match(/jpg/)
    end

    it "should resize the image to exactly the given dimensions and maintain file type" do
      @image_processor = described_class.new(:pad)
      padded_image = @image_processor.call(@minimagic_image, 200, 200)
      padded_image = MiniMagick::Image.open(padded_image.path)
      expect(padded_image.width).to be(200)
      expect(padded_image.height).to be(200)
      expect(padded_image["format"]).to match(/JPEG/)
      expect(File.extname(padded_image.path)).to match(/jpg/)
    end
  end
end
