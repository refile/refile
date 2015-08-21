require "refile/test_app"

feature "simple form upload" do
  scenario "renders a normal input" do
    visit "/simple_form/posts/new"
    attach_file "Document", path("hello.txt")
  end
end
