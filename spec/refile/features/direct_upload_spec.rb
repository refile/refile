require "refile/test_app"

feature "Direct HTTP post file uploads", :js do
  scenario "Successfully upload a file" do
    visit "/direct/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Document", path("hello.txt")

    expect(page).to have_content("Upload started")
    expect(page).to have_content("Upload success")
    expect(page).to have_content("Upload complete")

    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post")
    result = Net::HTTP.get_response(URI(find_link("Document")[:href])).body.chomp
    expect(result).to eq("hello")
  end

  scenario "Fail to upload a file that is too large" do
    visit "/direct/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Document", path("large.txt")

    expect(page).to have_content("Upload started")
    expect(page).to have_content("Upload failure error")
  end
end

