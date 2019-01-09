require "refile/test_app"

feature "single attribute form upload" do
  scenario "upload a single file insteaf of an array of files" do
    visit "/single/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Documents", path("hello.txt")
    click_button "Create"

    expect(download_link("Document: hello.txt")).to eq("hello")
  end

  scenario "Edit with changes" do
    visit "/single/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Documents", path("hello.txt")
    click_button "Create"

    visit "/single/posts/#{Post.last.id}/edit"
    attach_file "Documents", path("monkey.txt")
    click_button "Update"

    expect(download_link("Document: monkey.txt")).to eq("monkey")
    expect(page).not_to have_link("Document: hello.txt")
  end

  scenario "Edit without changes" do
    visit "/single/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Documents", path("hello.txt")
    click_button "Create"

    visit "/single/posts/#{Post.last.id}/edit"
    click_button "Update"

    expect(download_link("Document: hello.txt")).to eq("hello")
  end
end
