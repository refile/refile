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

  scenario "Edit with changes" do
    visit "/multiple/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Documents", [path("hello.txt"), path("world.txt")]
    click_button "Create"

    click_link "Edit multiple"
    attach_file "Documents", [path("monkey.txt")]
    click_button "Update"

    expect(download_link("Document: monkey.txt")).to eq("monkey")
    expect(page).not_to have_link("Document: hello.txt")
    expect(page).not_to have_link("Document: world.txt")
  end

  scenario "Edit without changes" do
    visit "/multiple/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Documents", [path("hello.txt"), path("world.txt")]
    click_button "Create"

    click_link "Edit multiple"
    click_button "Update"

    expect(download_link("Document: hello.txt")).to eq("hello")
    expect(download_link("Document: world.txt")).to eq("world")
  end

  describe "with direct upload" do
    scenario "Successfully upload a file" do
      visit "/direct/posts/new"
      fill_in "Title", with: "A cool post"
      attach_file "Documents", [path("hello.txt"), path("world.txt")]

      expect(page).to have_content("Upload started")
      expect(page).to have_content("Upload success")
      expect(page).to have_content("Upload complete")
      expect(page).to have_content("All uploads complete")

      click_button "Create"

      expect(download_link("Document: hello.txt")).to eq("hello")
      expect(download_link("Document: world.txt")).to eq("world")
    end
  end

  describe "with presigned upload" do
    scenario "Successfully upload a file" do
      visit "/presigned/posts/new"
      fill_in "Title", with: "A cool post"
      attach_file "Documents", [path("hello.txt"), path("world.txt")]

      expect(page).to have_content("Presign start")
      expect(page).to have_content("Presign complete")
      expect(page).to have_content("Upload started")
      expect(page).to have_content("Upload complete token accepted")
      expect(page).to have_content("Upload success token accepted")

      click_button "Create"

      expect(page).to have_selector("h1", text: "A cool post")
      expect(download_link("Document: hello.txt")).to eq("hello")
      expect(download_link("Document: world.txt")).to eq("world")
    end

    scenario "Fail to upload a file that is too large" do
      visit "/presigned/posts/new"
      fill_in "Title", with: "A cool post"
      attach_file "Documents", [path("large.txt"), path("world.txt")]

      expect(page).to have_content("Presign start")
      expect(page).to have_content("Presign complete")
      expect(page).to have_content("Upload started")
      expect(page).to have_content("Upload failure too large")
    end
  end
end
