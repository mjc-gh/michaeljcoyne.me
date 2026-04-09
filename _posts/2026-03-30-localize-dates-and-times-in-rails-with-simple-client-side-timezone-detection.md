---
layout: post
title:  "Localize dates and times in Rails with simple client-side timezone detection"
date:   2026-03-31T12:00:00Z
description: Learn how to detect and store user timezone in browsers using JavaScript, Stimulus, and client-side cookies.
---

When your web browser makes a request to a website, it tells the server
which language to serve via the `Accept-Language` header. Your browser
does not tell the web server what time zone to use when serving content,
which is key to localizing dates and times.

Rails has excellent support for localizing times via `Time.use_zone`.
Using a bit of JavaScript and a client-side cookie, we can easily solve
the inherent localization gap in the browser.

I often use Stimulus with my Rails apps, though the following can be
easily adapted to pure JavaScript or to another framework or library.

```js
import { cookie } from 'cookie.js';
import jstz from 'jstimezonedetect';

import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    this.tz = jstz.determine();
    this.tzName = jstz.determine().name();

    cookie.set('TZ', this.tzName, { path: '/' });
  }
}
```

Next, we'll need to consume this cookie server-side and call
`Time.use_zone` via a controller action callback.

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  prepend_around_action :set_timezone

  def set_timezone
    tzone = cookies["TZ"] || "America/New_York"

    Time.use_zone(tzone) { yield }
  end
```

How easy is that? Now we can easily localize date and time values in views via:

```ruby
l @user.created_at, format: :short
```
