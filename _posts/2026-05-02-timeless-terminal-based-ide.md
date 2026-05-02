---
layout: post
title:  "Timeless Terminal Based \"IDE\""
date:   2026-05-02T11:20:00Z
description: "I've been using vim, tmux, and SSH as my core development tools for nearly two decades, and they continue to adapt seamlessly to modern AI and agentic development workflows."
---

This post is a bit of an homage to some of the development tools I have
used for almost two decades now. Despite their age and their simplicity,
these tools are timeless and have been easy to adapt to the AI and
Agentic Development era, proving that you don't always need a complex
IDE (Integrated Development Environment) to be productive.

### vim

My go-to code and text editor has been Vim for some time now. It was the
open-source Janus distribution from Yehuda Katz and Carl Lerche that
first drew me into Vim, and quite frankly, I don't know Vim without
Janus.

While the [repository](https://github.com/carlhuda/janus) has become a
bit stale over the years, I've recently
[forked](https://github.com/mjc-gh/janus) it and made some additions,
like [vim-ai](https://github.com/madox2/vim-ai), to its collection of
tools.

My [`.vimrc.after`
file](https://github.com/mjc-gh/dotfiles/blob/main/.vimrc.after) and my
[vim-ai roles file](https://github.com/mjc-gh/dotfiles/blob/main/vim-ai-roles.ini)
are both available on my dotfiles repo.

### tmux

Next on the list is [tmux](https://github.com/tmux/tmux), which is
really the workhorse of my terminal development experience. Within a
single terminal tab, I can have multiple processes and shells running at
once. My usual setup anchors vim at the #1 window spot, with windows for
testing tools, development services, and more, or an additional bash
shell for running commands and interacting with git.

More recently, either OpenCode or Claude Code will take up another
window spot and tmux overall is well suited for handling CLI-based
agentic tooling.

To make managing sessions easier, I use
[tmuxinator](https://github.com/tmuxinator/tmuxinator), which is a Ruby
gem for managing tmux sessions with a YAML file.

My [`.tmux.conf` file](https://github.com/mjc-gh/dotfiles/blob/main/.tmux.conf)
is also available in my dotfiles repo.

### ssh

Last on the list is [Secure Shell](https://en.wikipedia.org/wiki/Secure_Shell),
which is key for allowing me to develop from anywhere. I strongly prefer
to develop on Linux over using macOS, so for most projects I will SSH
into a Ubuntu development server I run at home. This server has plenty
of CPU and memory and lets me run Docker services and databases with
ease.

When not on my local network, in the past I've relied on Dynamic DNS and
router port forwarding. More recently, I've started to use
[Tailscale](https://tailscale.com/) for private networking. I cannot
recommend Tailscale enough, it's a great product!

### My Terminal IDE

These 3 tools are the cornerstrong of my terminal IDE. All of these
tools are also well suited for running AI and Agentic tools.
