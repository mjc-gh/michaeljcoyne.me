---
layout: post
title:  "Authenticated Encryption for Rails 5.2 Cookies and Sessions"
date:   2017-09-06T12:00:00Z
description: "Rails 5.2 added AES-GCM encryption for sessions and cookies, reducing ciphertext size by 30% and improving speed by 25% with stronger security."
---

*This post was originally posted on [Medium](https://medium.com/@michaeljcoyne/authenticated-encryption-for-rails-5-2-cookies-and-sessions-3f87b1d21fec).*

With the release of Rails version 5.2, sessions and encrypted cookies are now protected with Authenticated Encryption via AES with GCM mode.

In general, [Authenticated Encryption (AE)](https://en.wikipedia.org/wiki/Authenticated_encryption) aims to provide both encryption and authentication into a single programming interface. Output from an AE cipher will contain both the resulting cipher text as well as authentication tag usually in the form of a [Message Authentication Code (MAC)](https://en.m.wikipedia.org/wiki/Message_authentication_code). Authentication is needed when encrypting messages in order to avoid various attacks on the underlying encryption cipher.

Authenticated Encryption through the GCM cipher was first introduced in Rails 5.1 in [PR 25874](https://github.com/rails/rails/pull/25874). This PR introduced support for the cipher to the `ActiveSupport::MessageEncryptor` class. The next minor version added AE support for sessions and cookies in [PR 28132](https://github.com/rails/rails/pull/28132). All existing sessions and cookies encrypted with the old scheme are automatically migrated to the new scheme.

As a result encrypted cookie ciphertexts are now [30% smaller](https://github.com/mikeycgto/message_encryptor-benchmark#results). Additionally, because encryption and authentication happen in a single step with GCM, these cookies and messages are now processed roughly [25% faster](https://github.com/mikeycgto/message_encryptor-benchmark#results) than compared to the old scheme.

Check out the [ActiveSupport](https://github.com/bdewater/rails/blob/9d90728e7b2d455c38cc8049f85e88dfe12a23d1/activesupport/CHANGELOG.md) and [ActionPack](https://github.com/mikeycgto/rails/blob/5a3ba63d9abad86b7f6dd36a92cfaf722e52760b/actionpack/CHANGELOG.md) CHANGELOGs for more details!
