# Refile

[![Gem Version](https://badge.fury.io/rb/refile.svg)](http://badge.fury.io/rb/refile)
[![Build Status](https://travis-ci.org/elabs/refile.svg?branch=master)](https://travis-ci.org/elabs/refile)
[![Code Climate](https://codeclimate.com/github/elabs/refile/badges/gpa.svg)](https://codeclimate.com/github/elabs/refile)
[![Inline docs](http://inch-ci.org/github/elabs/refile.svg?branch=master)](http://inch-ci.org/github/elabs/refile)

Refile is a modern file upload library for Ruby applications. It is simple, yet
powerful.

Links:

- [API documentation](http://www.rubydoc.info/gems/refile)
- [Source Code](https://github.com/elabs/refile)

Features:

- Configurable backends, file system, S3, etc...
- Convenient integration with ORMs
- On the fly manipulation of images and other files
- Streaming IO for fast and memory friendly uploads
- Works across form redisplays, i.e. when validations fail, even on S3
- Effortless direct uploads, even to S3

## Quick start, Rails

Add the gem:

``` ruby
gem "mini_magick"
gem "refile", require: ["refile/rails", "refile/image_processing"]
```

We're requiring both Refile's Rails integration and image processing via the
[MiniMagick](https://github.com/minimagick/minimagick) gem, which requires
[ImageMagick](http://imagemagick.org/) to be installed. To install it simply
run:

``` sh
brew install imagemagick # OS X
sudo apt-get install imagemagick # Ubuntu
```

Use the `attachment` method to use Refile in a model:

``` ruby
class User < ActiveRecord::Base
  attachment :profile_image
end
```

Generate a migration:

``` sh
rails generate migration add_profile_image_to_users profile_image_id:string
rake db:migrate
```

Add an attachment field to your form:

``` erb
<%= form_for @user do |form| %>
  <%= form.attachment_field :profile_image %>
<% end %>
```

Set up strong parameters:

``` ruby
def user_params
  params.require(:user).permit(:profile_image)
end
```

And start uploading! Finally show the file in your view:

``` erb
<%= image_tag attachment_url(@user, :profile_image, :fill, 300, 300) %>
```

## How it works

Refile consists of several parts:

1. Backends: cache and persist files
2. Model attachments: map files to model columns
3. A Rack application: streams files and accepts uploads
4. Rails helpers: conveniently generate markup in your views
5. A JavaScript library: facilitates direct uploads

Let's look at each of these in more detail!

## 1. Backend

Files are uploaded to a backend. The backend assigns an ID to this file, which
will be unique for this file within the backend.

Let's look at a simple example of using the backend:

``` ruby
backend = Refile::Backend::FileSystem.new("tmp")

file = backend.upload(StringIO.new("hello"))
file.id # => "b205bc..."
file.read # => "hello"

backend.get(file.id).read # => "hello"
```

As you may notice, backends are "flat". Files do not have directories, nor do
they have names or permissions, they are only identified by their ID.

Refile has a global registry of backends, accessed through `Refile.backends`.

There are two "special" backends, which are only really special in that they
are the default backends for attachments. They are `cache` and `store`.

The cache is intended to be transient. Files are added here before they are
meant to be permanently stored. Usually files are then moved to the store for
permanent storage, but this isn't always the case.

Suppose for example that a user uploads a file in a form and receives a
validation error. In that case the file has been temporarily stored in the
cache. The user might decide to fix the error and resubmit, at which point the
file will be promoted to the store. On the other hand, the user might simply
give up and leave, now the file is left in the cache for later cleanup.

Refile has convenient accessors for setting the `cache` and `store`, so for
example you can switch to the S3 backend like this:

``` ruby
# config/initializers/refile.rb
require "refile/backend/s3"

aws = {
  access_key_id: "xyz",
  secret_access_key: "abc",
  bucket: "my-bucket",
}
Refile.cache = Refile::Backend::S3.new(prefix: "cache", **aws)
Refile.store = Refile::Backend::S3.new(prefix: "store", **aws)
```

And add to your Gemfile:
```ruby
gem "aws-sdk"
```

Try this in the quick start example above and your files are now uploaded to
S3.

Backends also provide the option of restricting the size of files they accept.
For example:

``` ruby
Refile.cache = Refile::Backend::S3.new(max_size: 10.megabytes, ...)
```

The Refile gem ships with [S3](lib/refile/backend/s3.rb) and
[FileSystem](lib/refile/backend/file_system.rb) backends. Additional backends
are provided by other gems.

- [Fog](https://github.com/elabs/refile-fog) provides support for a ton of
  different cloud storage providers, including Google Storage and Rackspace
  CloudFiles.
- [Postgresql](https://github.com/krists/refile-postgres)
- [In Memory](https://github.com/jnicklas/refile-memory)

### Uploadable

The `upload` method on backends can be called with a variety of objects. It
requires that the object passed to it behaves similarly to Ruby IO objects, in
particular it must implement the methods `size`, `read(length = nil, buffer =
nil)`, `eof?` and `close`. All of `File`, `Tempfile`,
`ActionDispath::UploadedFile` and `StringIO` implement this interface, however
`String` does not. If you want to upload a file from a `String` you must wrap
it in a `StringIO` first.

## 2. Attachments

You've already seen the `attachment` method:

``` ruby
class User < ActiveRecord::Base
  attachment :profile_image
end
```

Calling `attachment` generates a getter and setter with the given name. When
you assign a file to the setter, it is uploaded to the cache:

``` ruby
User.new

# with a ActionDispatch::UploadedFile
user.profile_image = params[:file]

# with a regular File object
File.open("/some/path", "rb") do |file|
  user.profile_image = file
end

# or a StringIO
user.profile_image = StringIO.new("hello world")

user.profile_image.id # => "fec421..."
user.profile_image.read # => "hello world"
```

When you call `save` on the record, the uploaded file is transferred from the
cache to the store. Where possible, Refile does this move efficiently. For example
if both `cache` and `store` are on the same S3 account, instead of downloading
the file and uploading it again, Refile will simply issue a copy command to S3.

### Other ORMs

Refile is built to integrate with ORMs other than ActiveRecord, but this being
a very young gem, such integrations do not yet exist. Take a look at the [ActiveRecord
integration](lib/refile/attachment/active_record.rb), building your own should
not be too difficult.

### Pure Ruby classes

You can also use attachments in pure Ruby classes like this:

``` ruby
class User
  extend Refile::Attachment

  attr_accessor :profile_image_id

  attachment :profile_image
end
```

## 3. Rack Application

Refile includes a Rack application (an endpoint, not a middleware), written in
Sinatra. This application streams files from backends and can even accept file
uploads and upload them to backends.

**Important:** Unlike other file upload solutions, Refile always streams your files through your
application. It cannot generate URLs to your files. This means that you should
**always** put a CDN or other HTTP cache in front of your application. Serving
files through your app takes a lot of resources and you want it to happen rarely.

Setting this up is actually quite simple, you can use the same CDN you would use
for your application's static assets. [This blog post](http://www.happybearsoftware.com/use-cloudfront-and-the-rails-asset-pipeline-to-speed-up-your-app.html)
explains how to set this up (bonus: faster static assets!). Once you've set this
up, simply configure Refile to use your CDN:

``` ruby
Refile.host = "//your-dist-url.cloudfront.net"
```

Using a [protocol-relative URL](http://www.paulirish.com/2010/the-protocol-relative-url/) for `Refile.host` is recommended.

### Mounting

If you are using Rails and have required [refile/rails.rb](lib/refile/rails.rb),
then the Rack application is mounted for you at `/attachments`. You should be able
to see this when you run `rake routes`.

You could also run the application on its own, it doesn't need to be mounted to
work.

### Retrieving files

Files can be retrieved from the application by calling:

```
GET /attachments/:backend_name/:id/:filename
```

The `:filename` serves no other purpose than generating a nice name when the user
downloads the file, it does not in any way affect the downloaded file. For caching
purposes you should always use the same filename for the same file. The Rails helpers
default this to the name of the column.

### Processing

Refile provides on the fly processing of files. You can trigger it by calling
a URL like this:

```
GET /attachments/:backend_name/:processor_name/*args/:id/:filename
```

Suppose we have uploaded a file:

``` ruby
Refile.cache.upload(StringIO.new("hello")).id # => "a4e8ce"
```

And we've defined a processor like this:

``` ruby
Refile.processor :reverse do |file|
  StringIO.new(file.read.reverse)
end
```

Then you could do the following.

``` sh
curl http://127.0.0.1:3000/attachments/cache/reverse/a4e8ce/some_file.txt
elloh
```

Refile calls `call` on the processor and passes in the retrieved file, as well
as all additional arguments sent through the URL. See the
[built in image processors](lib/refile/image_processing.rb) for a more advanced
example.

## 4. Rails helpers

Refile provides the `attachment_field` form helper which generates a file field
as well as a hidden field. This field keeps track of the file in case it is not
yet permanently stored, for example if validations fail. It is also used for
direct and presigned uploads. For this reason it is highly recommended to use
`attachment_field` instead of `file_field`.

``` erb
<%= form_for @user do |form| %>
  <%= form.attachment_field :profile_image %>
<% end %>
```

Will generate something like:

``` html
<form action="/users" enctype="multipart/form-data" method="post">
  <input name="user[profile_image]" type="hidden">
  <input name="user[profile_image]" type="file">
</form>
```

The `attachment_url` helper can then be used for generating URLs for the uploaded
files:

``` erb
<%= link_to "Image", attachment_url(@user, :profile_image) %>
```

Any additional arguments to it are included in the URL as processor arguments:

``` erb
<%= link_to "Image", attachment_url(@user, :profile_image, :fill, 300, 300) %>
```

There's also a helper for generating image tags:

``` erb
<%= attachment_image_tag(@user, :profile_image, :fill, 300, 300) %>
```

With this helper you can specify an image which is used as a fallback in case
no file has been uploaded:

``` erb
<%= attachment_image_tag(@user, :profile_image, :fill, 300, 300, fallback: "default.png") %>
```

## 5. JavaScript library

Refile's JavaScript library is small but powerful.

Uploading files is slow, so anything we can do to speed up the process is going
to lead to happier users. One way to cheat is to start uploading files directly
after the user has chosen a file, instead of waiting until they hit the submit
button. This provides a significantly better user experience. Implementing this
is usually tricky, but thankfully Refile makes it very easy.

First, load the JavaScript file. If you're using the asset pipeline, you can
simply include it like this:

``` javascript
//= require refile
```

Otherwise you can grab a copy [here](https://raw.githubusercontent.com/elabs/refile/master/app/assets/javascripts/refile.js).
Be sure to always update your copy of this file when you upgrade to the latest
Refile version.

Now mark the field for direct upload:

``` erb
<%= form.attachment_field :profile_image, direct: true %>
```

There is no step 3 ;)

The file is now uploaded to the `cache` immediately after the user chooses a file.
If you try this in the browser, you'll notice that an AJAX request is fired as
soon as you choose a file. Then when you submit to the server, the file is no
longer submitted, only its id.

If you want to improve the experience of this, the JavaScript library fires
a couple of custom DOM events. These events bubble, so you can also listen for
them on the form for example:

``` javascript
form.addEventListener("upload:start", function() {
  // ...
});

form.addEventListener("upload:success", function() {
  // ...
});

input.addEventListener("upload:progress", function() {
  // ...
});
```

You can also listen for them with jQuery, even with event delegation:

``` javascript
$(document).on("upload:start", "form", function(e) {
  // ...
});
```

This way you could for example disable the submit button until all files have
uploaded:

``` javascript
$(document).on("upload:start", "form", function(e) {
  $(this).find("input[type=submit]").attr("disabled", true)
});

$(document).on("upload:complete", "form", function(e) {
  if(!$(this).find("input.uploading").length) {
    $(this).find("input[type=submit]").removeAttr("disabled")
  }
});
```

### Presigned uploads

Amazon S3 supports uploads directly from the browser to S3 buckets. With this
feature you can bypass your application entirely; uploads never hit your application
at all. Unfortunately the default configuration of S3 buckets does not allow
cross site AJAX requests from posting to buckets. Fixing this is easy though.

- Open the AWS S3 console and locate your bucket
- Right click on it and choose "Properties"
- Open the "Permission" section
- Click "Add CORS Configuration"

The default configuration only allows "GET", you'll want to allow "POST" as
well. You'll also want to permit the "Content-Type" and "Origin" headers.

It could look something like this:

``` xml
<CORSConfiguration>
    <CORSRule>
        <AllowedOrigin>*</AllowedOrigin>
        <AllowedMethod>GET</AllowedMethod>
        <AllowedMethod>POST</AllowedMethod>
        <MaxAgeSeconds>3000</MaxAgeSeconds>
        <AllowedHeader>Authorization</AllowedHeader>
        <AllowedHeader>Content-Type</AllowedHeader>
        <AllowedHeader>Origin</AllowedHeader>
    </CORSRule>
</CORSConfiguration>
```

If you're paranoid you can restrict the allowed origin to only your domain, but
since your bucket is only writable with authentication anyway, this shouldn't
be necessary.

Note that you do not need to, and in fact you shouldn't, make your bucket world
writable.

Once you've put in the new configuration, click "Save".

Now you can enable presigned uploads:

``` erb
<%= form.attachment_field :profile_image, presigned: true %>
```

You can also enable both direct and presigned uploads, and it'll fall back to
direct uploads if presigned uploads aren't available. This is useful if you're
using the FileSystem backend in development or test mode and the S3 backend in
production mode.

``` erb
<%= form.attachment_field :profile_image, direct: true, presigned: true %>
```

### Browser compatibility

Refile's JavaScript library requires HTML5 features which are unavailable on
IE9 and earlier versions. All other major browsers are supported.

## Additional metadata

In the quick start example above, we chose to only store the file id, but often
it is useful to store the file's filename, size and content type as well.
Refile makes it easy to extract this data and store it alongside the id. All you
need to do is add columns for these:

``` ruby
class StoreMetadata < ActiveRecord::Migration
  def change
    add_column :users, :profile_image_filename, :string
    add_column :users, :profile_image_size, :integer
    add_column :users, :profile_image_content_type, :string
  end
end
```

These columns will now be filled automatically.

## File type validations

Refile can check that attached files have a given content type or extension.
This allows you to warn users if they try to upload an invalid file.

**Important:** You should regard this as a convenience feature for your users,
not a security feature. Both file extension and content type can easily be
spoofed.

In order to limit attachments to an extension or content type, you can provide
them like this:

``` ruby
attachment :cv, extension: "pdf"
attachment :profile_image, content_type: "image/jpeg"
```

You can also provide a list of content types or extensions:

``` ruby
attachment :cv, extension: ["pdf", "doc"]
attachment :profile_image, content_type: ["image/jpeg", "image/png", "image/gif"]
```

Since the combination of JPEG, PNG and GIF is so common, you can also specify
this more succinctly like this:

``` ruby
attachment :profile_image, type: :image
```

When a user uploads a file with an invalid extension or content type and
submits the form, they'll be presented with a validation error.

If you use a particular content type or set of content types frequently
you can define your own types like this:

``` ruby
Refile.types[:document] = Refile::Type.new(:document,
  content_type: %w[text/plain application/pdf]
)
```

Now you can use them like this:

``` ruby
attachment :profile_image, type: :document
```

## Removing attached files

File input fields unfortunately do not have the option of removing an already
uploaded file. This is problematic when editing a model which has a file attached
and the user wants to remove this file. To work around this, Refile automatically
adds an attribute to your model when you use the `attachment` method, which is
designed to be used with a checkbox in a form.

``` erb
<%= form_for @user do |form| %>
  <%= form.label :profile_image %>
  <%= form.attachment_field :profile_image %>

  <%= form.check_box :remove_profile_image %>
  <%= form.label :remove_profile_image %>
<% end %>
```

Don't forget to permit this attribute in your controller:

``` ruby
def user_params
  params.require(:user).permit(:profile_image, :remove_profile_image)
end
```

Now when you check this checkbox and submit the form, the previously attached
file will be removed.

## Fetching remote files by URL

You might want to give you users the option of uploading a file by its URL.
This could be either just via a textfield or through some other interface.
Refile makes it easy to fetch this file and upload it. Just add a field like
this:

``` erb
<%= form_for @user do |form| %>
  <%= form.label :profile_image, "Attach image" %>
  <%= form.attachment_field :profile_image %>

  <%= form.label :remote_profile_image_url, "Or specify URL" %>
  <%= form.text_field :remote_profile_image_url %>
<% end %>
```

Then permit this field in your controller:

``` ruby
def user_params
  params.require(:user).permit(:profile_image, :remote_profile_image_url)
end
```

Refile will now fetch the file from the given URL, following redirects if
needed.

## Cache expiry

Files will accumulate in your cache, and you'll probably want to remove them
after some time.

The FileSystem backend does not currently provide any method of doing this. PRs
welcome ;)

On S3 this can be conveniently handled through lifecycle rules. Exactly how
depends a bit on your setup. If you are using the suggested setup of having
one bucket with `cache` and `store` being directories in that bucket (or prefixes
in S3 parlance), then follow the following steps, otherwise adapt them to your
needs:

- Open the AWS S3 console and locate your bucket
- Right click on it and choose "Properties"
- Open the "Lifecycle" section
- Click "Add rule"
- Choose "Apply the rule to: A prefix"
- Enter "cache/" as the prefix (trailing slash!)
- Click "Configure rule"
- For "Action on Objects" you'll probably want to choose "Permanently Delete Only"
- Choose whatever number of days you're comfortable with, I chose "1"
- Click "Review" and finally "Create and activate Rule"

## License

[MIT](LICENSE.txt)
