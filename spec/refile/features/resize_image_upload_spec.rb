require "refile/test_app"

feature "Direct HTTP post file uploads", :js do
  scenario "Successfully resize an image before upload it" do
    visit "/resize_image/posts/new"
    fill_in "Title", with: "A cool post"
    attach_file "Image", path("image.jpg")

    expect(page).to have_content("Upload started")
    expect(page).to have_content("Upload success")
    expect(page).to have_content("Upload complete")

    click_button "Create"

    expect(page).to have_selector("h1", text: "A cool post")
    expect(page).to have_selector("img")

    start = Time.now
    loop do
      break if find("img")["complete"]

      fail "Image still not loaded" if Time.now > start + 5.seconds

      sleep 0.1
    end

    expect(page.evaluate_script("$('img')[0].clientWidth")).to eq 400
  end
end
