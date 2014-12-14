require "refile/test_app"

feature "Normal HTTP Post file uploads" do
  scenario "Successfully upload a file" do
    visit "/normal/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Document", path("hello.txt")
    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post")
    click_link("Document")
    expect(page.source.chomp).to eq("hello")
  end

  scenario "Fail to upload a file that is too large" do
    visit "/normal/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Document", path("large.txt")
    click_button "Create"

    expect(page).to have_selector(".field_with_errors")
    expect(page).to have_content("Document is too large")
  end

  scenario "Upload a file via form redisplay" do
    visit "/normal/posts/new"
    attach_file "Document", path("hello.txt")
    click_button "Create"
    fill_in "Title", with: "A cool post"
    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post")
    click_link("Document")
    expect(page.source.chomp).to eq("hello")
  end

  scenario "Format conversion" do
    visit "/normal/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Document", path("hello.txt")
    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post")
    click_link("Convert to Upper")
    expect(page.source.chomp).to eq("HELLO")
  end

  scenario "Successfully remove an uploaded file" do
    visit "/normal/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Document", path("hello.txt")
    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post")
    expect(page).to have_selector(:link, "Document")
    click_link("Edit")

    check "Remove document"
    click_button "Update"
    expect(page).to have_selector("h1", text: "A cool post")
    expect(page).to_not have_selector(:link, "Document")
  end

  scenario "Upload a file from a remote URL" do
    stub_request(:get, "http://www.example.com/some_file").to_return(status: 200, body: "abc", headers: { "Content-Length" => 3 })

    visit "/normal/posts/new"
    fill_in "Title", with: "A cool post"
    fill_in "Remote document url", with: "http://www.example.com/some_file"
    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post")
    click_link("Document")
    expect(page.source.chomp).to eq("abc")
  end
end
