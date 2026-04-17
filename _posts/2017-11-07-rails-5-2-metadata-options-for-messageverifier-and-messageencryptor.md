---
layout: post
title:  "Rails 5.2 Metadata Options for MessageVerifier and MessageEncryptor"
date:   2017-11-07T12:00:00Z
description: "Rails 5.2 introduces purpose and expiry metadata options to MessageEncryptor and MessageVerifier classes, enabling developers to create more secure encrypted and signed messages by preventing cross-feature replay attacks and automatically expiring time-sensitive tokens."
---

*This post was originally posted on [Medium](https://medium.com/@michaeljcoyne/rails-5-2-metadata-options-for-messageverifier-and-messageencryptor-79540de86f9b).*

The upcoming release of Rails version 5.2, two new metadata fields for expiry and purpose information have been added to both the `MessageEncryptor` and `MessageVerifier` classes. These metadata features were developed and implemented as part of the [Rails Google Summer of Code 2017 project](https://summerofcode.withgoogle.com/projects/#6118848381059072). Both classes implement the same metadata API for encrypted and signed messages.

### Purpose Metadata

First lets explore the `:purpose` metadata option. This option lets us specify a string or symbol that will be included within the message when encrypting or generating a signed message. When we then decrypt or verify the message at a later point, we also supply the known purpose option and if the purpose matches the option supplied during the earlier step the message is decrypted or verified and returned.

Below is a small example borrowed straight from the docs. We see how only when the correct `:purpose` option of “login” is supplied, the encrypted message is returned:

```
> token = crypt.encrypt_and_sign("this is the chair", purpose: :login)
=> "aWEwbH...52272eb3"
> crypt.decrypt_and_verify(token, purpose: :login)
=> "this is the chair"
> crypt.decrypt_and_verify(token, purpose: :shipping)
=> nil
> crypt.decrypt_and_verify(token)
=> nil
```

The `:purpose` option works exactly same for `MessageVerifier` as well:

```
> token = @verifier.generate("this is the chair", purpose: :login)
=> "BAhJIhZ0...6b8d5190"
> @verifier.verified(token, purpose: :login)
=> "this is the chair"
> @verifier.verified(token, purpose: :shipping)
=> nil
> @verifier.verified(token)
=> nil
```

Supplying a `:purpose` is useful if the same key is used for encrypted or signed messages for different parts or features of your application. Messages from one feature could be replayed and potentially accepted as valid for another feature. Such cases could lead to unexpected side-effects or security flaws in your application design! Thus if you‘re using either of these classes or the framework provided [message_verifier](http://api.rubyonrails.org/classes/Rails/Application.html#method-i-message_verifier) instance in your application, it is highly recommend to now include a `:purpose` option.

### Expiry Metadata

Expiry metadata comes in two forms either using an `:expires_in` or `:expires_on` option. The former expects an `ActiveSupport::Duration` instance and the latter expect either a `Time`, `Date`, or `DateTime` instance.

Once again looking at the docs, we can see how easy it is to set expiry metadata for either `MessageEncryptor` or `MessageVerifier` messages:

```
> crypt.encrypt_and_sign(parcel, expires_in: 1.month)
> crypt.encrypt_and_sign(doowad, expires_at: Time.now.end_of_year)> @verifier.generate(parcel, expires_in: 1.month)
> @verifier.generate(doowad, expires_at: Time.now.end_of_year)
```

Messages encrypted or signed with this API will now only return the deserialized message before the expiration date and time. After the expiration date and time is passed, `nil` will be returned instead.

```
> token = crypt.encrypt_and_sign({ uid: 1 }, expires_in: 30.minutes)
=> "OVBxVC9y...486702be"
> crypt.decrypt_and_verify(token)
=> { uid: 1 }
# After 30 minutes
> crypt.decrypt_and_verify(token)
=> nil
```

Both of these metadata options are extremely useful when implementing various security-related features such as sign-in tokens or authentication cookies for different services. Later posts will explore both generating sign-in tokens as well as securing ActionCable connections using these new metadata features!
