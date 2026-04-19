---
layout: post
title:  "Simple and Secure Magic Login Links with GlobalID"
date:   2026-04-19T11:20:00Z
description: "Learn how to implement secure, passwordless magic link authentication in Rails using ActiveSupport's Global ID gem to generate cryptographically signed tokens with built-in expiration and replay attack protection."
---

Included within Rails and `ActiveSupport` is a small gem called [Global ID](https://github.com/rails/globalid). This gem is used throughout the framework for identifying individual model records via a standardized URI string.

This is how ActiveJob will serialize model parameters passed to jobs. Instead of serializing the entire model object, which is bad practice with backends like Sidekiq or Solid Queue, ActiveJob will automatically serialize models into Global ID-encoded URIs and will automatically find these records in your database when the job runs at some point in the future.

Global ID has another feature in the form of a method, `to_signed_global_id`, that returns cryptographically signed URIs for an individual record. These URIs can be used as a secure token for a magic sign-in link.

My usual implementation for Global ID magic links is as follows. First, I'll create a model concern that adds a couple of methods for creating signed URIs and securely locating records:

```ruby
module MagicLinkable
  extend ActiveSupport::Concern

  class_methods do
    def find_by_magic_link_token(token, for:)
      GlobalID::Locator.locate_signed(token, for:)
    end
  end

  def generate_magic_link_token(expires_in: 24.hours, for:)
    to_signed_global_id(expires_in:, for:).to_s
  end
end
```

The `MagicLinkable` concern would likely be included in your `User` model. That said, it really depends on your application and your use case.

The `generate_magic_link_token` method would generally be used with a mailer; however, the delivery mechanism could vary.

```ruby
token = generate_magic_link_token(for: :registration)

UserMailer.with(user: user, token:).complete_registration.deliver_later
```

Notice the `for` kwarg parameter. This parameter lets us scope the signed URI to prevent replay attacks across the application. For example, a signed Global ID for registration cannot be reused for login.

Next, I'll create a simple controller concern that lets the application consume signed Global IDs via a `verify` action that can be used with a `GET` request:

```ruby
module UserVerifiable
  extend ActiveSupport::Concern

  def verify
    @user = User.find_by_magic_link_token(params[:token], for: verification_purpose)

    if @user.nil?
      redirect_on_verification_failed, flash: { alert: I18n.t("invalid", scope: flash_i18n_namespace) }
    else
	  handle_verification_success
    end
  end

  private

  def verification_purpose = controller_name.singularize
end
```

This concern is then used in my registration and sessions controllers as follows:

```ruby
# config/routes.rb
namespace :users do
  resources :sessions, only: [:new, :create] do
    collection { get :verify }
  end

  resources :registrations, only: [:new, :create] do
    collection { get :verify }
  end
end

# app/controllers/users/sessions_controller.rb
class Users::SessionsController < ApplicationController
  include UserVerifiable

  # other actions...

  private

  def redirect_on_verification_failed
	redirect_to login_url, alert: "Invalid token"
  end

  def handle_verification_success
	redirect_to home_url, notice: "Sign in successful"
  end
end

# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < ApplicationController
  include UserVerifiable

  private

  def redirect_on_verification_failed
    redirect_to sign_up_url, alert: "Invalid token"
  end

  def handle_verification_success
    redirect_to home_url, notice: "Sign in successful"
  end
end
```

If you are using something like Devise or Revise Auth, I'd suggest adding new controllers rather than trying to extend the controllers included by those gems. For instance:

```ruby
# config/routes.rb
namespace :users do
  resources :session_links, only: [] do
    collection { :verify }
  end

  resources :registration_links, only: [] do
    collection { :verify }
  end
end
```
Overall, Global ID is a really useful feature of Rails with many uses.
