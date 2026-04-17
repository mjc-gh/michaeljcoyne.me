---
layout: post
title:  "Understanding the secret_key_base in Ruby on Rails"
date:   2017-09-05T12:00:00Z
description: "An overview of how the secret_key_base works and what it is used for in the Ruby on Rails framework"
---

*This post was originally posted on [Medium](https://medium.com/@michaeljcoyne/understanding-the-secret-key-base-in-ruby-on-rails-ce2f6f9968a1).*

Have you ever wondered what the `secret_key_base` value is and how it’s used in a Rails application? This configuration value was introduced in Rails 4 and is usually defined on a per-environment basis. It’s purpose is simple: _to be the secret input for the application’s_ `key_generator` _method._

This method is accessible through `Rails.application.key_generator`. The method accepts no arguments and returns an `ActiveSupport::CachingKeyGenerator` instance. Keys are then derived using the `generate_key` method provided by the `CachingKeyGenerator` class. The `secret_key_base` is thus responsible for reducing the configuration burden on developers while still allowing separate and disperse security features to function using separate keys.

The `CachingKeyGenerator` in particular wraps the `ActiveSupport::KeyGenerator` class. As it’s name indicates, it caches and stores the derived key result in an internal Hash, where the entries are indexed by their salt input.

<b>[other]Deriving a key from the application’s key_generator[/other]</b>

The application’s `key_generator`, and thus `secret_key_base`, are used by three core features within the Rails framework:

1.  Deriving keys for encrypted cookies which are accessible via `cookies.encrypted`.
2.  Deriving the key for HMAC signed cookies which are accessible via `cookies.signed`.
3.  Deriving keys for all of the application’s named `[message_verifier](http://api.rubyonrails.org/classes/Rails/Application.html#method-i-message_verifier)` instances.

### Encrypted Cookies

These cookies provide both integrity and confidentiality to their contents through encryption. [Rails’ session cookies](http://guides.rubyonrails.org/security.html#what-are-sessions-questionmark) are built upon encrypted cookies because of these properties.

Depending on the cipher used one to two keys will be generated from the `secret_key_base`. If [GCM encryption](https://medium.com/@mikeycgto/authenticated-encryption-for-rails-5-2-cookies-and-sessions-3f87b1d21fec) is used a key is derived using the salt defined by `config.action_dispatch.authenticated_encrypted_cookie_salt`. This value defaults to `“authenticated encrypted cookie”`.

If CBC encryption is used, two keys are derived. This is done because using AES in CBC mode we [must also authenticate the message using a MAC](https://moxie.org/blog/the-cryptographic-doom-principle/). The encryption key and verification keys are derived using salts defined by the configuration values `config.action_dispatch.encrypted_cookie_salt` and `config.action_dispatch.encrypted_signed_cookie_salt`. They default to `“encrypted cookie”` and `“signed encrypted cookie”` respectively.

### Signed Cookies

These cookies are secured using an HMAC with the SHA1 hash function. They thus provide integrity to their contents. They follow as a similar implementation as encrypted cookies and use a key derived from `secret_base_key`.

When deriving the key for signed cookies, the configuration value defined at `config.action_dispatch.signed_cookie_salt` is used for the salt. This value defaults to `“signed cookie”`.

### Application Message Verifier

The last place `secret_key_base` is used in the Rails framework is by the application’s `message_verifier` method. Much like the application’s `key_generator` method, this method is also accessible via `Rails.application`. This method accepts a `verifier_name` string as it’s only argument. This argument is used to index and save the `[MessageVerifie](http://api.rubyonrails.org/classes/ActiveSupport/MessageVerifier.html#method-c-new)r` instance. The argument is also used as the salt input for deriving a key from `secret_base_base`.

The application’s `message_verifier` method provides a easy and convenient security API for providing message integrity features. It is commonly used to implement “remember me” tokens or limiting access to resource with signed URL. This method is also used by the new [ActiveStorage feature](https://github.com/rails/rails/blob/a3f7407e7c0bdfafda4c574e12a68e9cbbef82c5/activestorage/lib/active_storage/engine.rb#L30-L36) which was introduced in Rails 5.2.

### About ActiveSupport::KeyGenerator

The `ActiveSupport::KeyGenerator` just wraps a [Key Derivation Function](https://en.wikipedia.org/wiki/Key_derivation_function) named [PBKDF2](https://en.wikipedia.org/wiki/PBKDF2). This KDF is actually not the best option considering it is meant for password-based key derivation. Specifically, PBKDF2 is designed to take human-generated passphrases and, through a technique known as [Key Stretching](https://en.wikipedia.org/wiki/Key_stretching), produce a stronger key through an iterative process. The actual `secret_key_base` values used in real-world Rails applications are generated from secure random numbers usually using `SecureRandom` and `rake secrets`. As such, these values are already significantly more secure and sufficiently random than a human generated passphrase.

In fact, most Rails applications are using a `secret_key_base` value that is 64 bytes long. [When using PBKDF2 for key derivation](https://github.com/rails/rails/pull/8112#issuecomment-10449212), the effective output for a given key is limited to 20-bytes or 160-bits. A better fit for the keys derived throughout Rails would be to use [HKDF](https://en.wikipedia.org/wiki/HKDF) instead. HKDF employs an “extract-then-expand” approach and permits longer output keys to be generated as a result.

### What’s Next

I’ve begun to explore implementing HKDF for Rails. I plan to create a Pull Request with these improvements in the future — stay tuned!
