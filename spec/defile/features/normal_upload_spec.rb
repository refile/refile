require "defile/test_app"

feature "Normal HTTP Post file uploads" do
  scenario "Successfully upload a file" do
    visit "/normal/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Image", path("hello.txt")
    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post")
    click_link("Image")
    expect(page.source.chomp).to eq("hello")
  end

  scenario "Upload a file via form redisplay"
end
