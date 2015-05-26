require "refile/test_app"

feature "Normal HTTP Post file uploads" do
  scenario "Successfully upload a file" do
    visit "/normal/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Document", path("hello.txt")
    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post")
    expect(page).to have_selector(".content-type", text: "text/plain")
    expect(page).to have_selector(".size", text: "6")
    expect(page).to have_selector(".filename", text: "hello.txt")
    expect(download_link("Document")).to eq("hello")
  end

  scenario "Fail to upload a file that is too large" do
    visit "/normal/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Document", path("large.txt")
    click_button "Create"

    expect(page).to have_selector(".field_with_errors")
    expect(page).to have_content("Document is too large")
  end

  scenario "Fail to upload a file that has the wrong format" do
    visit "/normal/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Image", path("hello.txt")
    click_button "Create"

    expect(page).to have_selector(".field_with_errors")
    expect(page).to have_content("Image has an invalid file format")
  end

  scenario "Fail to upload a file that has the wrong format then submit" do
    visit "/normal/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Image", path("hello.txt")
    click_button "Create"

    expect(page).to have_selector(".field_with_errors")
    expect(page).to have_content("Image has an invalid file format")
    click_button "Create"
    expect(page).to have_selector("h1", text: "A cool post")
    expect(page).not_to have_link("Document")
  end

  scenario "Successfully update a record with an attached file" do
    visit "/normal/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Image", path("image.jpg")
    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post")
    click_link("Edit")

    fill_in "Title", with: "A very cool post"

    click_button "Update"
    expect(page).to have_selector("h1", text: "A very cool post")
  end

  # FIXME: the only reason this is js:true is because the rack_test driver
  # doesn't submit file+metadata correctly.
  scenario "Upload a file via form redisplay", js: true do
    visit "/normal/posts/new"
    attach_file "Document", path("hello.txt")
    click_button "Create"
    fill_in "Title", with: "A cool post"
    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post")
    expect(page).to have_selector(".content-type", text: "text/plain")
    expect(page).to have_selector(".size", text: "6")
    expect(page).to have_selector(".filename", text: "hello.txt")
    expect(download_link("Document")).to eq("hello")
  end

  scenario "Format conversion" do
    visit "/normal/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Document", path("hello.txt")
    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post")
    expect(download_link("Convert to Upper")).to eq("HELLO")
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
    expect(page).not_to have_selector(:link, "Document")
    expect(page).not_to have_selector(".content-type", text: "text/plain")
    expect(page).not_to have_selector(".size", text: "6")
    expect(page).not_to have_selector(".filename", text: "hello.txt")
  end

  scenario "Successfully remove a record with an uploaded file" do
    visit "/normal/posts/new"
    fill_in "Title", with: "A cool post about to be deleted"
    attach_file "Document", path("hello.txt")
    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post about to be deleted")
    click_link("Delete")
    expect(page).to_not have_content("A cool post about to be deleted")
  end

  scenario "Upload a file from a remote URL" do
    url = "http://www.example.com/foo/bar/some_file.png?some-query-string=true"

    stub_request(:get, url).to_return(
      status: 200,
      body: "abc",
      headers: {
        "Content-Length" => 3,
        "Content-Type" => "image/png"
      }
    )

    visit "/normal/posts/new"
    fill_in "Title", with: "A cool post"
    fill_in "Remote document url", with: url
    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post")
    expect(download_link("Document")).to eq("abc")
    expect(page).to have_selector(".content-type", text: "image/png")
    expect(page).to have_selector(".size", text: "3")
    expect(page).to have_selector(".filename", text: "some_file.png", exact: true)
  end
end
