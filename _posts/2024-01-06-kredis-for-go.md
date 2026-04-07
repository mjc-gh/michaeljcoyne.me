---
layout: post
title:  "Introducing a Go version of Kredis (\"Keyed Redis\") from the Rails ecosystem"
date:   2024-01-06T23:25:47Z
description: Introducing a Go port of Rails' Kredis library, providing a set of higher-level data structures that encapsulate Redis keys as coherent objects to simplify data manipulation and enable interoperability between Go and Ruby services.
---

[Kredis](https://github.com/rails/kredis), from the Rails ecosystem, is a valuable library that encourages a more object-oriented approach when interacting with various data structures and types on Redis. I've previously used Kredis for scenarios like caching a set of available times in an appointment booking app, or employing the hash type to track daily API usage.

In a bid to gain a deeper understanding of Go, generics, and the intricacies of the Redis package, I recently translated this fantastic Ruby library to Go. Overall, I'm quite happy with the end result. Go is just object-oriented enough to appreciate the benefits this package can bring to practical examples in your Go code. This package could be especially useful if you are connecting Go and Ruby services via Redis.

Here's a brief example of how to use the `Set` [type](https://github.com/mjc-gh/kredis-go#set):

```go
t := time.Now()
times := []time.Time{t, t.Add(1 * time.Hour), t.Add(2 * time.Hour), t.Add(3 * time.Hour)}

set, _ := kredis.NewTimeSet("times")
set.Add(times...)
members, _ := set.Members()

fmt.Println(set.Includes(t)) // true
fmt.Println(set.Includes(t.Add(4 * time.Hour))) // false
fmt.Printf("%d %v\n", set.Size(), members)
// 4 [2024-01-05 02:00:00 +0000 UTC ...]

sample := make([]time.Time, 2)
n, _ := set.Sample(sample)

fmt.Printf("n = %d %v\n", n, sample) // random sample of 2 members
```

Documentation for all available types can be found in the [README](https://github.com/mjc-gh/kredis-go) as well as the docs [Go package docs v0.0.1-alpha1](https://pkg.go.dev/github.com/mjc-gh/kredis-go@v0.0.1-alpha1).

PRs and enhancement suggestions are more than welcomed! Kredis is excellent for temporary data storage use cases, as most types support expiration. Let me know in the comments if you find this package useful 💞
