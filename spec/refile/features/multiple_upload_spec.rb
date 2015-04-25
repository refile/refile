require "refile/test_app"

feature "Multiple file uploads", :js do
  scenario "Upload multiple files" do
    visit "/multiple/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Documents", [path("hello.txt"), path("world.txt")]
    click_button "Create"

    expect(download_link("Document: hello.txt")).to eq("hello")
    expect(download_link("Document: world.txt")).to eq("world")
  end

  scenario "Fail to upload a file that is too large" do
    visit "/multiple/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Documents", [path("hello.txt"), path("large.txt")]
    click_button "Create"

    expect(page).to have_content("Documents is invalid")
  end

  scenario "Fail to upload a file that has the wrong format then submit" do
    visit "/multiple/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Documents", [path("hello.txt"), path("image.jpg")]
    click_button "Create"

    expect(page).to have_content("Documents is invalid")
    click_button "Create"
    expect(page).to have_selector("h1", text: "A cool post")
    expect(page).not_to have_link("Document")
  end

  scenario "Upload files via form redisplay", js: true do
    visit "/multiple/posts/new"
    attach_file "Documents", [path("hello.txt"), path("world.txt")]
    click_button "Create"
    fill_in "Title", with: "A cool post"
    click_button "Create"

    expect(download_link("Document: hello.txt")).to eq("hello")
    expect(download_link("Document: world.txt")).to eq("world")
  end
end
