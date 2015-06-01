require "refile/test_app"

feature "Direct HTTP post file uploads", :js do
  scenario "Successfully upload a file" do
    visit "/direct/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Document", path("hello.txt")

    expect(page).to have_content("Upload started")
    expect(page).to have_content("Upload success")
    expect(page).to have_content("Upload complete")
    expect(page).to have_content("All uploads complete")

    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post")
    expect(page).to have_selector(".content-type", text: "text/plain")
    expect(page).to have_selector(".size", text: "6")
    expect(page).to have_selector(".filename", text: "hello.txt")
    expect(download_link("Document")).to eq("hello")
  end

  scenario "Fail to upload a file that is too large" do
    visit "/direct/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Document", path("large.txt")

    expect(page).to have_content("Upload started")
    expect(page).to have_content("Upload failure error")
  end

  scenario "Upload a file after validation failure" do
    visit "/direct/posts/new"
    fill_in "Title", with: "A cool post"
    check "Requires document"
    click_button "Create"

    attach_file "Document", path("hello.txt")

    expect(page).to have_content("Upload started")
    expect(page).to have_content("Upload success")
    expect(page).to have_content("Upload complete")

    click_button "Create"

    expect(download_link("Document")).to eq("hello")
  end

  scenario "Fail to upload a file that has wrong format" do
    visit "/direct/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Image", path("large.txt")

    expect(page).to have_content("Upload started")
    expect(page).to have_content("Upload success")
    expect(page).to have_content("Upload complete")

    click_button "Create"

    expect(page).to have_selector(".field_with_errors")
    expect(page).to have_content("Image has an invalid file format")
  end
end
