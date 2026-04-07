---
layout: post
title:  "Elegantly integrate Mixpanel with your Rails app using built-in instrumentation"
date:   2022-12-29T14:34:44Z
description: Integrating Mixpanel into a Rails application often leads to controllers cluttered with tracking logic that distracts from your core business logic. This guide demonstrates how to leverage Rails' built-in instrumentation API to create a clean, decoupled analytics layer that keeps your codebase elegant and maintainable.
---

[Mixpanel](https://mixpanel.com/) is a truly impressive product analytics tool that can provide rich insights to engineering, product, and marketing teams alike. [Server-side Mixpanel integrations](https://developer.mixpanel.com/docs/client-side-vs-server-side-tracking#server-side-tracking) are able to produce an extremely reliable analytics layer with highly consistent event tracking. Deeply integrating Mixpanel in this way enables you to fully analyze your product and discover useful insights.

We've all seen it before though, analytic API calls littered throughout a controller and its actions. This can be an eyesore to engineers, to say the least. It may also lead to event naming inconsistencies or future breaks in event tracking if we're not careful. Lastly, those external HTTP requests from the event tracking calls should not be inlined with requests — that's what background job are for.

**Turns out, there's a better way to achieve deep integration with Mixpanel using the built-in framework instrumentation provided by Rails!**

---

💡 **NOTE:** _While this post is focused on Mixpanel, the technical advice given here can apply to many analytics and mar-tech tools. In the past, I've used these techniques at [Publicist](https://www.publicist.co) for [Intercom](https://intercom.com/) as well!_

---

## ActiveSupport Instrumentation

Before we dive into some specifics, let's cover some basics. The [Instrumentation API](https://guides.rubyonrails.org/active_support_instrumentation.html) is part of the `ActiveSupport` set of core Ruby language utilities. It provides a small interface for measuring and publishing arbitrary events. The Rails framework publishes a lot of diagnostic events through this interface. Many Application Performance Monitoring (APM) tools use this API to collect information about how long a database query or view render took.

We'll be using two framework event hooks with the Mixpanel integration:

1. The `process_action.action_controller` [event](
   https://guides.rubyonrails.org/active_support_instrumentation.html#process-action-action-controller) which occurs after a controller has fully processed an action. This event comes from `ActionController`.
2. The `deliver.action_mailer` [event](https://guides.rubyonrails.org/active_support_instrumentation.html#action-mailer) from `ActionMailer`. This event is triggered when a mailer has sent an email.

## Tracking Advice

The first thing to point out about Mixpanel is the need to determine what your [Distinct User IDs](https://help.mixpanel.com/hc/en-us/articles/115004509406-What-is-distinct-id-) are. This ID needs to be unique and is associated with every event. Often other analytics or mar-tech tools have a similar unique or distinct User ID tracking requirements so it's best to get this out of the way immediately.

While it's possible to use the primary key of your users or accounts table, it's better practice to use a random GUID that is assigned when a record is created. This unique identifier that isn't directly tied to your database can be used across analytics and mar-tech tools and not just with Mixpanel.

If you are using Postgres, you just add a `uuid` [type column](https://guides.rubyonrails.org/active_record_postgresql.html#uuid) to your `users` or `accounts` table as follows:

```ruby
change_table :users do |t|
  t.uuid :public_id, null: false
end

add_index :users, :public_id, unique: true
```

If you aren't using Postgres or another RDBMS that supports the UUID column type, a string column will also work. It's probably best to add a unique index while we're at it. Now for the last step, add a `before_validation` callback to the `User` model to set this value on create:

```ruby
class User < ApplicationRecord
  before_validation(on: :create) do
    self.public_id ||= SecureRandom.uuid
  end
end
```

## Implementation Details

Now that we have all the background information and some model setup in place, we can start to integrate deeply with Mixpanel. Personally, I prefer to use a class based approach when defining new Rails instrumentation subscribers. More details about this approach can be found in the Rails documentation for `ActiveSupport::Notifications` under the ["Subscribers" section](https://api.rubyonrails.org/classes/ActiveSupport/Notifications.html#module-ActiveSupport::Notifications-label-Subscribers).

So let's begin the implementation by defining a new class in `app/instruments/process_action_instrument.rb`. The skeleton for this new class and its required `call` method is taken directly from the documentation mentioned above:

```ruby
class ProcessActionInstrument
  def call(name, started, finished, unique_id, payload)
    Rails.logger.debug ['notification:', name, started, finished, unique_id, payload].join(' ')
  end
end
```

To make sure the class is properly autoloaded, we have to add this new directory to the autoload paths. This can be done by adding the following line to your `config/application.rb` file as such:

```ruby
module MyAmazingApp
  class Application < Rails::Application
    # Add to autoloaded paths
    config.autoload_paths << Rails.root.join('app', 'instruments').to_s
  end
end
```

Let's now subscribe this new "instrument" class to the `process_action.action_controller` event using a new initializer defined in `config/initializers/mixpanel_instrumentation.rb`. This initializer will use the `to_prepare` [initializer](https://guides.rubyonrails.org/configuring.html#initialization-events) so we can play nice with auto-reloading:

```ruby
Rails.application.config.to_prepare do
  if Rails.env.development? # unsubscribe to reload instrument class changes
    ActiveSupport::Notifications.unsubscribe 'process_action.action_controller'
  end
  
	ActiveSupport::Notifications.subscribe 'process_action.action_controller', ProcessActionInstrument.new
end
```

If all was setup correctly, we should now see some new logging in the `log/development.log` file by the newly subscribed "instrument" class:

```
Processing by ArticlesController#index as HTML
  User Load (0.9ms)  SELECT "users".* FROM "users" WHERE "users"."id" = ? ORDER BY "users"."id" ASC LIMIT ?  [["id", 1], ["LIMIT", 1]]
  Rendering layout layouts/application.html.erb
  Rendering articles/index.html.erb within layouts/application
  Article Load (0.2ms)  SELECT "articles".* FROM "articles"
  ↳ app/views/articles/index.html.erb:6
  Rendered articles/index.html.erb within layouts/application (Duration: 5.7ms | Allocations: 1325)
  Rendered layout layouts/application.html.erb (Duration: 66.7ms | Allocations: 10778)
notification: process_action.action_controller 2022-12-16 18:12:11 -0500 2022-12-16 18:12:11 -0500 b705b1b56d0fac92ab79 {:controller=>"ArticlesController", :action=>"index", :request=>#<ActionDispatch::Request GET "http://127.0.0.1:3000/" for 127.0.0.1>, :params=>{"controller"=>"articles", "action"=>"index"}, :headers=> ... }
```

I've truncated all the output that is generated for the sake of brevity, but you get the idea!

### Tracking Action Controller Events

With the new instrument class in place, we can start to build the actual implementation for tracking events in your Rails app. First and foremost, I like to define a method for generating consistent event names across the entire application. While the exact specifics of your event naming conventions do not necessarily matter, it's absolutely critical that you pick one and stick to it.

```ruby
class ProcessActionInstrument
  private
  
  def event_name(payload)
    controller_name = payload[:controller][0..-11].underscore.gsub(%r(/), '_')

    case payload[:action]
    when 'index'
      "View #{controller_name.titleize}"
    else
      "#{payload[:action].titleize} #{controller_name.singularize.titleize}"
    end
  end
end
```

The above `event_name` method will help us achieve broad consistency across all controllers and actions. Essentially, it'll take the controller name, remove the `Controller` part from it, and replaces all `::` and `/` characters with an underscore.

The above code also handles the `index` action slightly differently and prepends "View" to it and keeps the event name pluralized (assuming your controllers are following standard Rails naming conventions). For all other action names, the action name is just prepended as is the to event name.

Both branches in this `case` statement will `titleize` the event name in order to produce slightly more human friendly event names. Keep in mind that Mixpanel isn't just for us engineers, it's for the whole company. Thus, it's best to keep things as human friendly as possible when it comes to naming events and properties.

To give a few examples, I've shown a few controller and action name pairs and the output that the `event_name` method will produce with them:

```ruby
'ArticlesController#index'           => 'View Articles'
'ArticlesController#show'            => 'Show Article'
'Calendar::EventsController#create'  => 'Create Calendar Event'
```

Let's start using the new `event_name` method now and test it out with the skeleton instrument class. We'll make use of some ["tagged" logging](https://api.rubyonrails.org/classes/ActiveSupport/TaggedLogging.html) to make it easier to spot new output in the logs:

```ruby
class ProcessActionInstrument  
  def call(name, started, finished, unique_id, payload)
    Rails.logger.tagged 'ProcessActionInstrument' do |log|
      log.debug "event_name => #{event_name(payload)}"
    end
  end
end
```

We can make a request now to the application see the resulting logs once more:

```
Started GET "/articles/new" for 127.0.0.1 at 2022-12-16 18:55:39 -0500
Processing by ArticlesController#new as HTML
  User Load (0.1ms)  SELECT "users".* FROM "users" WHERE "users"."id" = ? ORDER BY "users"."id" ASC LIMIT ?  [["id", 1], ["LIMIT", 1]]
  Rendering layout layouts/application.html.erb
  Rendering articles/new.html.erb within layouts/application
  Rendered articles/_form.html.erb (Duration: 28.5ms | Allocations: 3137)
  Rendered articles/new.html.erb within layouts/application (Duration: 31.8ms | Allocations: 3503)
  Rendered layout layouts/application.html.erb (Duration: 35.2ms | Allocations: 4648)
[ProcessActionInstrument] event_name => New Article
```

Next, we'll need some event properties to include with the Mixpanel events for every action we track. Define a new method called `event_properties` which extracts a common resource ID property for every action from the `param` hash. Consider this new method below:

```ruby
class ProcessActionInstrument  
  private
  
  def event_properties(payload)
    params = payload[:params]
    request = payload[:request]
    id = params[:id]

    {}.tap do |props|
      props["#{payload[:controller].demodulize[0..-11].singularize.titleize} ID"] = id if id

      params.keys.each do |key|
        props["#{key.titleize} ID"] = params[key] if key.ends_with? '_id'
      end
      
      props.update request.env[:mixpanel_extra_properties] if request.env.key? :mixpanel_extra_properties
    end
  end
end
```

This method will always return a hash that may or may not be empty. If the method finds an `:id` parameter in the `params` hash, it'll include the ID within the event properties. Again, we'll try to generate a human friendly name for this property based upon the controller itself. Using the  `ArticlesControllers` from above, this method just adds a single entry named `Article ID` to the returned hash.

Moving down through the method, we see it also enumerates all of the values within `params` specifically looking for entries that end in `_id`. This is meant to include any other ID values included in the parameters hash and particularly useful for nested resources. 

For instance, suppose we have a nested `CommentsController` with the following routing setup:

```ruby
resources :articles do
  resources :comments, except: :show
end
```

This method will include the parent `Article ID` as well as the `Comment ID` properties. Let's add more to the `call` method and see this in action:

```ruby
class ProcessActionInstrument
  def call(name, started, finished, unique_id, payload)
    Rails.logger.tagged('ProcessActionInstrument') do |log|
      log.debug "event_name => #{event_name(payload)}"
      log.debug "event_properties => #{event_properties(payload)}"
    end
  end
end
```

Now lets request an action for the `CommentsController` , say the edit action:

```
Started GET "/articles/1/comments/1/edit" for 127.0.0.1 at 2022-12-16 19:59:52 -0500
Processing by CommentsController#edit as HTML
  Parameters: {"article_id"=>"1", "id"=>"1"}
[ProcessActionInstrument] event_name => Edit Comment
[ProcessActionInstrument] event_properties => {"Article ID"=>"1", "Comment ID"=>"1"}
```

We can see in the additional logging that both IDs are present the hash returned by the new `event_properties` method.

Finally, there is the last `props.update` call that looks for additional properties directly in the Rack [environment hash](https://github.com/rack/rack/blob/main/SPEC.rdoc#the-environment-) stored under `request.env`. This `update` makes it easy to add more properties directly from controller actions. Consider this a bit of an escape hatch that can be used when the "default" integration just isn't enough.

For example, you could use the `:mixpanel_extra_properties` hash to track the text length of new comments as they are created. This can now be easily achieved by adding the following line to the `create` method of the `CommentsController`:

```ruby
class CommentsController < ApplicationController
	def create
    @comment = @article.comments.create(comment_params)
    @comment.posted_by = current_user

    if @comment.save     
    	request.env[:mixpanel_extra_properties] = { 'Comment Body Length' => @comment.body.size }
      
      redirect_to [@article, :comments], notice: "Comment was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

Let's look at the resulting logs once again to see the new event properties in action:

```
Started POST "/articles/1/comments" for 127.0.0.1 at 2022-12-16 20:25:35 -0500
Processing by CommentsController#create as HTML
  Parameters: {"authenticity_token"=>"[FILTERED]", "comment"=>{"body"=>"One more comment!"}, "commit"=>"Create Comment", "article_id"=>"1"}
Redirected to http://127.0.0.1:3000/articles/1/comments
[ProcessActionInstrument] event_name => Create Comment
[ProcessActionInstrument] event_properties => {"Article ID"=>"1", "Comment Body Length"=>17}
```

My suggestion is to choose your event properties wisely. I generally like to stick to the essentials and try to only use ID properties and other key data points. In my next article, we'll explore how to augment your Mixpanel analysis with [Lookup Tables](https://help.mixpanel.com/hc/en-us/articles/360044139291-Lookup-Tables-In-Depth), which makes it easy to add new data properties on the fly to Mixpanel and pairs very nicely with this deep ID tracking now implemented.

We need one last ingredient to get instrumentation based tracking fully integrated. We need to know which user performed the action before we can send events to Mixpanel (or any other analytics or mar-tech tool for that matter). For this post, we'll assume that Devise is being used. If you aren't using Devise, don't worry, I'll share some advice on how to identify users within the instrumentation class later in the post.

We'll add one more method to the instrument class named `event_user`. This method will look for the authenticated user from the Rack `env` hash via [Warden](https://github.com/wardencommunity/warden), which is what Devise is built on. This is actually rather convenient because we've already used the Rack `env` hash once in the implementation.

```ruby
class ProcessActionInstrument  
  private
  
  def event_user(payload)
    warden = payload[:request].env['warden']

    warden.user(:user) if warden.authenticated?(:user)
  end
end
```

If you aren't using Devise, I would suggest you make use of the `request.env` hash and add the `User` instance to the hash in your `ApplicationController` (or perhaps just the user's `public_id`).

We'll add more to the `call` method to use `event_user` and log its output:

```ruby
class ProcessActionInstrument  
  def call(name, started, finished, unique_id, payload)
    Rails.logger.tagged 'ProcessActionInstrument' do |log|
      log.debug "event_name => #{event_name(payload)}"
      log.debug "event_properties => #{event_properties(payload)}"
      log.debug "event_user => #{event_user(payload).inspect}"      
    end
  end
end
```

Making a quick request to the app and looking at the logs, we see that everything is working order as expected:

```
Started GET "/articles/1/comments" for 127.0.0.1 at 2022-12-16 20:42:29 -0500
Processing by CommentsController#index as HTML
  Parameters: {"article_id"=>"1"}
[ProcessActionInstrument] event_name => View Comments
[ProcessActionInstrument] event_properties => {"Article ID"=>"1"}
[ProcessActionInstrument] event_user => #<User id: 1, email: "test@example.com", public_id: "1e93f8ac-bf20-4176-beff-b9eebdf779a5", created_at: "2022-12-16 17:48:27.533165000 +0000", updated_at: "2022-12-16 17:48:27.533165000 +0000">
```

Now that we have these key support methods in place, we can add a couple more things that are necessary for a complete Mixpanel tracking solution. First, we'll *likely* want to only track "successful" requests and not track submission errors and other "not successful" requests. That is easily achieved via a guard statement at the top of the `call` method:

```ruby
class ProcessActionInstrument  
  def call(name, started, finished, unique_id, payload)
    return unless payload[:response]&.status.to_i.in? 200..399

    Rails.logger.tagged('ProcessActionInstrument') do |log|
      log.debug "event_name => #{event_name(payload)}"
      log.debug "event_properties => #{event_properties(payload)}"
      log.debug "event_user => #{event_user(payload).inspect}"
    end
  end
end
```

Now let's make a request with a form validation errors. Looking again in the logs, there should **not** be any instrument logs because this form submission resulted in a `422 Unprocessable Entity` response.

```
Started POST "/articles/1/comments" for 127.0.0.1 at 2022-12-16 20:52:35 -0500
Processing by CommentsController#create as HTML
  Parameters: {"authenticity_token"=>"[FILTERED]", "comment"=>{"body"=>""}, "commit"=>"Create Comment", "article_id"=>"1"}
Completed 422 Unprocessable Entity in 29ms (Views: 8.0ms | ActiveRecord: 0.3ms | Allocations: 5114)
```

Next, we'll probably want to add another guard statement and early return for when a user is not logged in. While Mixpanel can track anonymous users, this is beyond the extent of this post and it's something we can explore in detail in a future post. I'd also suggest ignoring requests for built-in Rails controllers as well.

```ruby
class ProcessActionInstrument  
  def call(name, started, finished, unique_id, payload)
    return unless payload[:response]&.status.to_i.in? 200..399
    return if payload[:request].path.starts_with?('/rails')
    
    user = event_user(payload)
    return unless user

    Rails.logger.tagged('ProcessActionInstrument') do |log|
      log.debug "event_name => #{event_name(payload)}"
      log.debug "event_properties => #{event_properties(payload)}"
      log.debug "event_user => #{user.inspect}"
    end
  end
end
```

Once more lets turn to the logs for an unauthenticated action, such as the sign in page, and ensure we see no logs:

```
Started GET "/users/sign_in" for ::1 at 2022-12-16 20:56:47 -0500
Completed 200 OK in 75ms (Views: 52.3ms | ActiveRecord: 0.7ms | Allocations: 23918)
```

Depending on your application, you may want to exclude additional routes as well. Keep in mind you have full access to the controller class name and action name being requested so adding more exclusion logic is very easy.

### Tracking Actions with ActiveJob

Now as I mentioned at the start of the post, we can take tracking to another level by utilizing [Active Job](https://guides.rubyonrails.org/active_job_basics.html) and pushing all Mixpanel API calls to a background worker queue. First, lets create a new job:

```
rails g job track_processed_action
```

It's also a good time to actually install the Ruby Mixpanel client into your application. If you haven't done so already, add `mixpanel-ruby` to your Gemfile now. For more details on the library itself, refer to the [project on Github](https://github.com/mixpanel/mixpanel-ruby). You will also need a Mixpanel API token to begin with server-side tracking. We'll assume this token has been added to the Rails credentials under `:mixpanel_token`.

The new job will do a couple of things in the end, but the first step is to define the `perform` method to take a `User` model instance, an event name, its properties, and an optional IP address.

```ruby
class TrackProcessedActionJob < ApplicationJob
  queue_as :low

  def perform(user, event_name, event_properties, ip = nil)
    ip ||= user.current_sign_in_ip || user.last_sign_in_ip

    mixpanel_client.track user.public_id, event_name, event_properties, ip
  end

  private

  def mixpanel_client
    @mixpanel_client ||= Mixpanel::Tracker.new(Rails.application.credentials[:mixpanel_token])
  end
end
```

It's very useful to include to the IP address with server-side tracking on Mixpanel in order to leverage their geo-location feature. This code assumes you are using the ["Trackable" module in Devise](https://www.rubydoc.info/github/plataformatec/devise/master/Devise/Models/Trackable) which adds the `current_sign_in_ip` and `last_sign_in_ip` attributes to your `User` model. If you are not using this module or do not want these defaults, it's easy enough to remove that bit of code:

With the job class initially implemented, we can test it out now with the Rails console:

```ruby
TrackProcessedActionJob.perform_now User.first, 'Test Event', { 'Property' => 'Value' }
```

If everything is setup correctly, you should now see a `"Test Event"` event and it's one custom property appear in your Mixpanel Events page :tada:

We still need to add one more element to the background job to utilize Mixpanel to its fullest extent. We'll want to make it easy to identify tracked users and potentially add arbitrary user properties to their profile on Mixpanel. These profiles do not change that often, so I would highly recommend adding a bit of logic to periodically update these the profiles every few days. To do this, add a new column to the users' table called `mixpanel_profile_last_set_at`. This column should allow `null` and use a `datetime` type. Next, we'll add the following methods to the job class:

```ruby
class TrackProcessedActionJob < ApplicationJob
  private

  def expand_user_properties(user)
    { '$email' => user.email,
      '$last_seen' => user.current_sign_in_at,
      '$created' => user.created_at,
      'sign_in_count' => user.sign_in_count }
  end

  def people_set_recent?(user)
    user.mixpanel_profile_last_set_at.nil? ||
      user.mixpanel_profile_last_set_at < 3.days.ago
  end
end
```

The first method, `expand_user_properties` just takes the `User` model instance and returns hash with some default properties set for each user profile. Some of these are special Mixpanel properties and are prefaced with the `$` symbol. Some are others that I find useful to include and also come from the "Trackable" module in Devise. This method in general is a placeholder and is meant to be updated with your own application and product specific properties.

Now let's update the `perform` method to also call `people.set` on the Mixpanel API to start setting user profiles:

```ruby
class TrackProcessedActionJob < ApplicationJob
  queue_as :low

  def perform(user, event_name, event_properties, ip = nil)
    ip ||= user.current_sign_in_ip || user.last_sign_in_ip

    mixpanel_client.track user.public_id, event_name, event_properties, ip
    
    return unless people_set_recent?
    
    mixpanel_client.people.set user.public_id, expand_user_properties(user), ip,
      '$ignore_time' => 'true'
    
    user.update_column :mixpanel_profile_last_set_at, Time.current
  end
end
```

Once again I would suggest using the Rails console to test out the job. If you call it multiple times, you should only see the `UPDATE` DB query once, thus indicating `people.set` is only called periodically.

```ruby
TrackProcessedActionJob.perform_now User.first, 'Test Event', { 'Property' => 'Value' }
```

You should now see some User properties present for your test user under the "Users" page on Mixpanel. To finish the integration, we need to make one last update to the `ProcessActionInstrument` class to queue this new job:

```ruby
class ProcessActionInstrument
  def call(name, started, finished, unique_id, payload)
    return unless payload[:response]&.status.to_i.in? 200..399

    user = event_user(payload)
    return unless user
   
    name = event_name(payload)
    props = event_properties(payload)

  	TrackProcessedActionJob.perform_later user, name, props, payload[:request].ip
  end
end
```

With this last implementation detail, we should have a fully working Mixpanel integration that utilizes Rails' instrumentation! You can start your app, make a few requests, and check your Mixpanel project for new events. Some other suggestions I would make are:

- Test your instrument and job classes as need. I'm a firm believer in TDD and there is no reason not to write some integration tests to ensure the `TrackProcessedActionJob` is queued when it should be. I'd also suggest testing the job class and the Mixpanel API integration more directly as well. This is a great place to use VCR or Webmock.

- Setup some configuration to **not** emit Mixpanel events in the `development` environment (and potentially even in `test` one too if you aren't mocking HTTP requests in general). This could be as simple as adding a guard statement to the ` TrackProcessedActionJob#perform` method to early return in `development` or when Mixpanel tracking is disabled as a configuration option.

- Add more logging to your `TrackProcessedActionJob` to better highlight Mixpanel events and their properties. This will make debugging your integration easier in the future and I would even always log events in `development` for debugging purposes. You can even use `ActiveSupport` to colorize logs:

  ```ruby
  Rails.logger.debug ActiveSupport::LogSubscriber.new.send(:color, "[TrackProcessedActionJob] #{user.public_id} - #{event_name} - #{event_properties}", :green)
  ```

### Tracking Mailer Events

Next up is tracking for mailer events. This gives full coverage to all points of interaction a user sees with your application. Creating funnel reports in Mixpanel for an email notification and its call-to-action has never been easier! This tracking will even utilize existing pieces of the implementation to keep the code DRY and consistent. To start, we'll add to the initializer from before:

```ruby
Rails.application.config.after_initialize do
  if Rails.env.development?
    ActiveSupport::Notifications.unsubscribe 'process_action.action_controller'
    ActiveSupport::Notifications.unsubscribe 'deliver.action_mailer'
  end
  
	ActiveSupport::Notifications.subscribe 'process_action.action_controller', ProcessActionInstrument.new
  ActiveSupport::Notifications.subscribe 'deliver.action_mailer', DeliverActionMailerInstrument.new
end
```

The `deliver.action_mailer` event has a far simpler payload, in fact it's a bit too simple. We'll be able to use the mailer class name, the `to` email address field, and the `subject` line to drive tracking. We'll first implement a new job named `TrackDeliverActionMailerJob` :

```
rails g job track_deliver_action_mailer
```

This job will take a single email address and look for the matching `User` in the database. When the user is found, we'll put together some simple event properties and queue the existing `TrackActionEventJob` from the prior section. If the user is not found, this job will early return. This is very similar to one of the guard statements we added to the `ProcessActionInstrument` class that halts the `call` method when there is no authenticated user.

```ruby
class TrackDeliverActionMailerJob < ApplicationJob
  queue_as :low

  def perform(email, mailer_name, subject)
    user = User.find_by(email: email)

    return unless user

    event_name = mailer_name.titleize
    event_props = { 'Subject' => subject }

    TrackActionEventJob.perform_later user, event_name, event_props
  end
end
```

Now define the new mailer instrument in `app/instruments/deliver_action_mailer_instrument.rb`. This new instrument class simply loops through all `:to` email addresses in the `payload` and queues the job we just implemented.

```ruby
class DeliverActionMailerInstrument
  def call(name, started, finished, unique_id, payload)
  	payload[:to].each do |email|
      TrackDeliverActionMailerJob.perform_later email, payload[:mailer], payload[:subject]
    end  	
  end
end
```

To test this integration, we can trigger a quick mailer in the app using the Rails console:

```ruby
CommentMailer.with(user: User.first, article: Article.first).notice.deliver
```

We should see some new logs now and more events on Mixpanel:

```
[ActiveJob] [TrackActionEventJob] Performing TrackActionEventJob (Job ID: 668596ff-341c-4aec-baea-e97b17270d71) from Async(low) enqueued at 2022-12-29T01:06:52Z with arguments: #<GlobalID:0x000000010b37f350 @uri=#<URI::GID gid://mixpanel-demo/User/1>>, "Comment Mailer", {"Subject"=>"You have a new comment on your article"}
[ActiveJob] [TrackActionEventJob] [TrackActionEventJob] 95662a1e-e1e1-4383-a125-52538f6c9b62 - Comment Mailer - {"Subject"=>"You have a new comment on your article"}
```

How easy was that 🎊

## Wrapping Up

You now have a pretty robust, server-side Mixpanel integration for Rails that is able to track all authenticated user's controller action requests and any emails your mailers send. You can augment event properties as needed from your controllers and add more user properties in a single location. All the API calls happen in the background, via Active Job, and you can put these jobs into your low priority worker queue.

To see all of the above in action I've put together a simple [demo app on GitHub](https://github.com/mjc-gh/mixpanel-rails-demo). Feel free to use the code in this repo as needed in your own applications.

**Stay tuned for my next article in this series about how to augment your Mixpanel analytics and insights via [Lookup Tables](https://help.mixpanel.com/hc/en-us/articles/360044139291-Lookup-Tables-In-Depth) that are periodically updated by your Rails app.**
