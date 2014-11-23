require "defile/test_app"

feature "Normal HTTP Post file uploads" do
  scenario "Successfully upload a file" do
    visit "/"
    expect(page).to have_content("Hello world")
  end

  scenario "Upload a file via form redisplay"
end
