# 0.6.2

Release date: 2015-09-10

- [CHANGED] Removed must-revalidate header, since it serves no purpose

# 0.6.1

Release date: 2015-09-11

- [FIXED] Include missing files in gem bundle

# 0.6.0

Release date: 2015-09-10

- [BREAKING] `Refile.direct_upload` has been renamed to `Refile.allow_uploads_to`.
- [BREAKING] `Refile.mount_point` no longer implicitly adds a leading slash.
- [BREAKING] Attachment URLs are now signed, it is no longer possible to generate them client-side
- [BREAKING] S3 support has been extracted to a separate gem, see https://github.com/refile/refile-s3
- [BREAKING] MiniMagick support has been extracted to a separate gem, see https://github.com/refile/refile-mini_magick
- [ADDED] `Refile.cdn_host` and `Refile.app_host`, since not all parts of a Refile should run behind a CDN
- [ADDED] Support for multiple file uploads via `accepts_attachments_for`
- [ADDED] Supports JRuby 9.0.0.0 and up
- [ADDED] Backends can configure what they consider a valid ID
- [ADDED] Refile files are rewindable
- [ADDED] Added shortcut to generate URLs to model
- [ADDED] `Refile.file_url` to generate a URL to a file without an attachment
- [ADDED] `attachment_url` can take a fallback
- [ADDED] Support for simple_form
- [FIXED] Multiple validation errors caused problems for attachment fields
- [FIXED] Using Refile with nested forms
- [FIXED] Problem finding hidden field when field is wrapped in error div
- [FIXED] Incorrect filename is sometimes extracted
- [FIXED] Make sure temporary files are flushed to disk
- [DEPRECATED] `Refile.host` is deprecated in favour of `Refile.cdn_host`

# 0.5.5

Release date: 2015-05-19

- [FIXED] Upgrade rest-client version due to security concerns.

# 0.5.4

Release date: 2015-04-14

- [FIXED] [Critical security issue](https://groups.google.com/forum/#!topic/ruby-security-ann/VIfMO2LvzNs).

# 0.5.3

Release date: 2015-01-18

- [FIXED] More stringent checks for ID validity.
- [CHANGED] `Refile.attachment_url` not uses `Refile.mount_point` as the prefix by default.

# 0.5.2

Release date: 2015-01-13

- [ADDED] Can generate URLs without using the Rails helper via `Refile.attachment_url`
- [FIXED] Regression in `attachment_image_tag`, was not using `Refile.host`.
- [FIXED] Record without file can be updated when content type and filename are not persisted
- [FIXED] Remove `id` attribute from hidden field, so it doesn't get confused with the file field

# 0.5.1

Release date: 2015-01-11

- [FIXED] Set content type from extension properly
- [FIXED] Support animated GIFs when changing format

# 0.5.0

Release date: 2015-01-09

- [ADDED] Can add custom types for easier content type validations
- [ADDED] Can persist filename, size and content type
- [CHANGED] The `cache_id` field is no longer necessary and no longer need to be permitted in the controller
- [CHANGED] Improved logging

# 0.4.2

Release date: 2014-12-27

- [FIXED] Regression in S3 backend

# 0.4.1

Release date: 2014-12-26

- [CHANGED] Improved IO performance
- [FIXED] Work around a bug in Ruby 2.2

# 0.4.0

Release date: 2014-12-26

- [ADDED] Pass through additional args to S3
- [ADDED] Rack app sets far future expiry headers
- [ADDED] Sinatra app supports CORS preflight requests
- [ADDED] Helpers can take `host` option
- [ADDED] File type validations
- [ADDED] attachment_field accept attribute is set from file type restrictions
- [CHANGED] Dynamically generated methods in attachments are included via Module
- [CHANGED] Rack app replaced with Sinatra app
- [FIXED] Various content type fixes in Sinatra app
- [FIXED] Don't set id of record if it is frozen

# 0.3.0

Release date: 2014-12-14

- [ADDED] Can upload files via URL

# 0.2.5

Release date: 2014-12-12

- [ADDED] CarrierWave style `remove_` attribute
- [ADDED] Files are deleted after model is destroyed
- [FIXED] Spec files can be required by external gems
- [FIXED] Refile should work inside other Rails engines

# 0.2.4

Release date: 2014-12-08

- [ADDED] Supports format option with image processing

# 0.2.3

Release date: 2014-12-08

- [ADDED] Support for passing format to processors
- [FIXED] Support IE10
- [FIXED] Gracefully degrade on IE9, IE8 and IE7
- [FIXED] Success event is fired at the appropriate time
- [FIXED] Works with apps which don't define root_url
