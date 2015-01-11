require "active_record"

I18n.enforce_available_locales = true

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: File.expand_path("test_app/db/db.sqlite", File.dirname(__FILE__)),
  verbosity: "quiet"
)

class TestMigration < ActiveRecord::Migration
  def self.up
    create_table :posts, force: true do |t|
      t.column :title, :string
      t.column :image_id, :string
      t.column :document_id, :string
      t.column :document_filename, :string
      t.column :document_content_type, :string
      t.column :document_size, :integer
    end
  end
end

quietly do
  TestMigration.up
end
