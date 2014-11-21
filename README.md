# Defile

Defile is a modern file upload library for Ruby applications. It is simple, yet
powerful. Defile is an attempt by CarrierWave's original author to fix the
design mistakes and overengineering in CarrierWave.

Features:

- Configurable backends, file system, S3, etc...
- Convenient integration with ORMs
- On the fly manipulation of images and other files
- Streaming IO for fast and memory friendly uploads
- Smooth Rails integration
- Works across form redisplays, i.e. when validations fail, even on S3

## Quick start, Rails

Add the gem:

``` ruby
gem "mini_magick"
gem "defile", require: ["defile/rails", "defile/image_processing"]
```

Use the `attachment` method to use Defile in a model:

``` ruby
class User < ActiveRecord::Base
  attachment :profile_image, type: :image
end
```

Generate a migration:

``` sh
rails generate migration add_profile_image_to_users profile_image_id:string
rake db:migrate
```

Add an attachment field to your form:

``` erb
<%= form_for User.new do |form| %>
  <%= form.attachment_field :profile_image %>
<% end %>
```

And start uploading! Finally show the file in your view:

``` erb
<%= image_tag attachment_url(@user, :profile_image, width: 300, height: 300, crop: :fill) %>
```

## How it works

Defile consists of three parts:

1. Backends, cache and persist files
2. Model attachments, map files to model columns
3. Rack middleware, streams files and optionally manipulates them

Let's look at each of these in more detail!

### 1. Backend

Files are uploaded to a backend. The backend assigns an ID to this file, which
will be unique for this file within the backend.

Let's look at a simple example of using the backend:

``` ruby
backend = Defile::Backend::FileSystem.new("tmp")

file = backend.upload(StringIO.new("hello"))
file.id # => "b205bc..."
file.read # => "hello"

backend.get(file.id).read # => "hello"
```

As you may notice, backends are "flat". Files do not have directories, nor do
they have names, they are only identified by their ID.

Defile has a global registry of backends, accessed through `Defile.backends`.

There are two "special" backends, which are only really special in that they
are the default backends for attachments. They are `cache` and `store`. The
cache is intended to be transient. Files are added here before they are meant
to be permanently stored. Usually files are then moved to the store for
permanent storage, but this isn't always the case.

Suppose for example that a user uploads a file in a form and receives a
validation error. In that case the file has been temporarily stored in the
cache. The user might decide to fix the error and resubmit, at which point the
file will be promoted to the store. On the other hand, the user might simply
give up and leave, now the file is left in the cache for later cleanup.

Defile has convenient accessor for setting the `cache` and `store`, so for
example you can switch to the S3 backend like this:

``` ruby
# config/initializers/defile.rb
require "defile/backend/s3"

aws = {
  access_key_id: "xyz",
  secret_access_key: "abc",
  bucket: "my-bucket",
}
Defile.cache = Defile::Backend::S3.new(prefix: "cache", **aws)
Defile.store = Defile::Backend::S3.new(prefix: "store", **aws)
```

Try this in the quick start example above and your files are now uploaded to
S3.

### 2. Attachments

You've already seen the `attachment` method:

``` ruby
class User < ActiveRecord::Base
  attachment :profile_image, type: :image
end
```

You can also use this in pure Ruby classes like this:

``` ruby
class User < ActiveRecord::Base
  extend Defile::Attachment

  attr_accessor :profile_image_id

  attachment :profile_image, type: :image
end
```

#### Restrictions

You may have noticed the `type` parameter. This parameter restricts which files
can be attached. For security reasons, this parameter is mandatory. Allowed
values are:

1. The symbol `:any` allowing files with any extension
2. The symbol `:image` which maps to allowing, `jpg`, `jpeg`, `gif` and `png`
   These are the commonly supported image formats on the web.
3. The name of an extension as a String, for example `"pdf"`.
4. An array of extensions. For example `%w[pdf txt doc]`

Attachment can also limit the size of uploaded files:

``` ruby
class User < ActiveRecord::Base
  attachment :profile_image, type: :image, max_size: 10.megabytes
end
```
