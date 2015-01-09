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
