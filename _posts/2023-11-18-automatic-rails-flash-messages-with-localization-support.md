---
layout: post
title:  "Automatic Rails Flash messages with Localization support"
date:   2023-11-18T23:42:06Z
description: Decouple user-facing text from Rails controllers by using a custom concern that automatically sets localized flash messages based on the action name and response status.
---

Every Rails developer knows about the [`flash`](https://api.rubyonrails.org/classes/ActionDispatch/Flash.html) feature and how it's often used to present alerts and notices after a user performs an action. These flashes can be set directly in a controller's action like so:

```ruby
def create
  @post = Post.new(post_params)
  if @post.save 
    redirect_to post_urls, flash: { notice: 'Post created successfully' }
  else
    render :new, status: :unprocessable_entity
  end
end
```

Having user-facing text in our controllers is a bit obtrusive though as it distracts from the action's business logic.

To minimize this while also maintaining robust user messaging, I often include the below concern in my controllers. This module will set up easy auto-assignment of flash messages from localizations!

```ruby
# app/controllers/concerns/flashable.rb
module Flashable
  extend ActiveSupport::Concern

  included do
    after_action :try_to_set_flash
  end

  def try_to_set_flash
    return unless request.post? || request.patch? || request.delete?

    catch :exception do
      case response.status
      when 200..399
        flash[:notice] = I18n.t('success', scope: flash_i18n_namespace, throw: true)
      when 400..499
        flash[:alert] = I18n.t('error', scope: flash_i18n_namespace, throw: true)
      end
    end
  end

  def flash_i18n_namespace
    "flash.#{controller_name}.#{action_name}"
  end
end
```

Once you've created this module in your code base, you can `include Flashable` in your `ApplicationController`. Next, create a new locale file under `config/locales/flashes.en.yml`.

The module expects flashes localization entries to be named using the controller and action. When the action was successful a "success" entry set to `flash[:notice]`. When the action failed, the "error" messages is set to `flash[:alert].`

```yaml
en:
  flash:
    posts:
      create:
        success: Post was successfully created
        error: Post was failed to save
    sessions:
      create:
        success: Login successful.
      destroy:
        success: Logout successful.
```

🎉 Happy coding!
