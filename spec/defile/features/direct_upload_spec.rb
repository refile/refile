require "defile/test_app"

feature "Direct HTTP post file uploads" do
  scenario "Successfully upload a file" do
    visit "/direct/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Document", path("hello.txt")

    expect(page).to have_content("Upload started")
    expect(page).to have_content("Upload progress")
    expect(page).to have_content("Upload finished")

    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post")
    click_link("Document")
    expect(page.source.chomp).to eq("hello")
  end

  scenario "Fail to upload a file that is too large" do
    visit "/direct/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Document", path("large.txt")
    click_button "Create"

    expect(page).to have_content("Upload started")
    expect(page).to have_content("Upload progress")
    expect(page).to have_content("Upload failed, too large")
  end
end

