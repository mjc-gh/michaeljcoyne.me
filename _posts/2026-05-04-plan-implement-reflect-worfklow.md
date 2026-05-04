---
layout: post
title:  "Plan, Implement, and Reflect Workflow"
date:   2026-05-04T11:00:00Z
description: "As I've adopted agentic development workflows using AI agents like Claude Code and Codex, I've found that a simple \"Plan, Implement, Reflect\" workflow has revolutionized the way I write software, allowing me to work more efficiently and effectively with these cutting-edge tools."
---

<p class="lead">All software that is worth building begins with a good plan.</p>

In the last 6 months or so, the modern software development and
engineering space has really evolved. With the advent of Claude Code,
Codex, and other open-source coding agents, the way we write code has
dramatically changed. The need for a good plan, however, has not
changed.

Generally, I’ve referred to these newer workflows and processes as
Agentic Development, though terms like [AI-Assisted Software
Development](https://en.wikipedia.org/wiki/AI-assisted_software_development)
or [Automatic
Programming](https://en.wikipedia.org/wiki/Automatic_programming) are
also being [used](https://antirez.com/news/159).

I wanted to write a brief post that describes some of my workflows using
AI agents to write software. These workflows are generally performed
explicitly via slash commands using
[OpenCode](https://opencode.ai/docs/commands/), my personal agentic tool
of choice.

For Codex and Claude Code, slash commands are now a legacy feature. As
of this writing, both appear to still be supported; however, that may
change. These workflows can easily be performed via “skills,” and both
Codex and Claude Code will let you explicitly invoke one with a slash
command.

The workflow is loosely based on the [“Research → Plan → Implement
Pattern” from Goose](https://goose-docs.ai/docs/tutorials/rpi/). When
I’m looking to add a feature, refactor some code, or fix a bug, my
workflow will have three distinct phases:

1. Plan
2. Implement
3. Reflect/Retro

All three stages are tightly bound to the project I am working on. In
fact, I will often include two plan and implement OpenCode slash
commands within the project’s repo. These two phases of the workflow
also require some sort of issue-tracking component. For personal
projects, I will use Github Issues. For work, I may use Shortcut or
JIRA. We will also need a way to programmatically read issues/stories
and update their contents via the command line for this agentic coding
workflow.

### Plan

Planning starts with writing an issue or story for what I want to
achieve. I'll provide a clear and concise title along with bullet points
on what we're building or refactoring. Issues may reference code or
files directly and will include markdown code samples and links as
needed.

Next, I'll run the plan command with my AI agent, passing along the
issue or story ID:

```
/plan 1234
```

When planning, I will often use more expensive models with bigger context windows. With OpenCode slash commands, this can be accomplished with the following YAML front matter:

```yaml
---
description: Refine a GitHub issue with implementation plan and checklist
model: openrouter/anthropic/claude-opus-4.6
---
```

Below is the content of my planning phase. Depending on your project and
issue tracker, the content may need to be edited to suit your use case
(especially with Step #4):

```markdown
Fetch GitHub issue #$1 and refine it with a detailed implementation plan.

**Instructions:**

1. Fetch the current issue content:
   `gh api repos/[GITHUG_USER]/[GITHUB_REPO]/issues/$1 | jq -r '"### \(.title)\n\(.body)"'`

2. Analyze the issue to understand:
   - What problem needs to be solved
   - What features or fixes are requested
   - Any constraints or requirements mentioned
   - Ask clarifying questions if needed

3. Explore the codebase thoroughly to:
   - Identify all files and components that will need changes
   - Understand the existing architecture and patterns
   - Find related code, tests, and dependencies
   - Note any potential challenges or edge cases

4. Create a comprehensive implementation plan that includes:
   - A clear summary of the approach
   - Step-by-step breakdown of changes needed
   - Files to be created or modified
   - Any database migrations required
   - Test coverage requirements
   - Always create a decisive plan without any options or alternatives; ask the user questions if needed

5. Format the refined issue with:
   - Original issue description preserved at the top
   - A "## Implementation Plan" section with the approach
   - A "## Checklist" section with actionable task items using `- [ ]` format

6. Update the issue on GitHub:
   `gh issue edit $1 --repo [GITHUG_USER]/[GITHUB_REPO] --body "REFINED_BODY"`

7. Report success and show a summary of the plan added to the issue.

**Important:**
- Preserve the original issue content; append the plan below it
- Keep checklist items specific and actionable
- Reference specific files and line numbers where helpful
- Always follow the project conventions
```

A core aspect of this workflow is *preserving planning artifacts*. This
is why GitHub issues or a story tracker is key for the workflow. Both my
original planning request and the planning output from the agent are
captured in the issue and commits for the implementation phase can link
to issues or stories. Each plan will also include a detailed checklist
and to-do list for the agent to complete in the implementation phase.

We can now review the plan in GitHub and make edits as needed. I can
also ask the agent to make modifications to the plan as necessary, and
the planning phase can be as iterative as needed.

One byproduct of capturing all this context is to help identify
validation and verification gaps that we can rectify with additional
tooling or testing. This is essential to building self-correcting
feedback loops so the agent produces the results we want. This is a
process that is more generally described as [“Harness
Engineering”](https://martinfowler.com/articles/harness-engineering.html).

Steps #1 and #6 will both need to be reworked for your issue tracker of
choice. It's easy to ask your code agent to make changes for you. Notice
in Step #1 the use of `jq` to slim down the content we’re passing along
from the GitHub issue. We’ll only relay the title and issue description
to the agent, thus reducing token usage.

### Implement

With a solid and thorough plan in place, the next phase is to implement
the changes and verify them. After planning and before implementing, I
will always *start a new session*. I'll also usually opt for a cheaper
model and will configure it again via front matter:

```yaml
---
description: Fetch a GitHub issue and implement it
model: openrouter/anthropic/claude-haiku-4.6
---
```

The contents of the implement command are as follows:

```markdown
Here is the GitHub issue to implement:

`gh api repos/[GITHUG_USER]/[GITHUB_REPO]/issues/$1 | jq -r '"### \(.title)\n\(.body)"'`

**Instructions:**

1. Analyze what needs to be implemented or fixed fetched issue
2. Follow the exact plan described in the issue
3. Implement the required changes following the project's coding
conventions
4. Follow the checklist in the issue and complete all tasks

**IMPORTANT**: Do NOT commit changes or call git. Only implement the code changes requested in the issue. The user will handle commits themselves.
```

This command is also going to “read” the issue or story, so whatever customizations made in Step #1 of the plan phase will need to be made here as well.

It’s critical that the agent doesn’t automatically make commits for us either. We’ll want to review the implementation once more locally before committing any code. We may also need to make some changes to the implementation and the session may become more iterative.

I'll usually have a [slash
command](https://github.com/mjc-gh/context_stash/blob/main/commands/commit.md)
or skill available for committing code and writing commit messages for
me, but that is beyond the scope of this post and the "Plan, Implement,
Reflect" workflow I am detailing.

### Reflect

Lastly, is the “Reflect” or “Retro” phase. We want to reflect on the
implementation session, which also includes the output of the planning
phase, and review our [`AGENTS.md`](http://AGENTS.md) file and our
project reference docs. This is an opportunity to improve the project's
documentation in order to reduce future efforts, both in terms of time
and token usage, when researching and planning new features or issues.

Below is my reflect command:

```markdown
---
description: Retro/Reflect on session and current documentation
---

Let’s hold a brief retro and reflect on this session and the latest changes made:

1. Review the `AGENTS.md` file and its reference files in the `doc/` directory
  - Identify context from this session that should be added to either `AGENTS.md` or reference `doc/` file
2. Provide a concise list of additions for me to review
  - If no useful context exists, say so
  - Only add context that reduces future research and planning efforts
3. Prioritize documentation accuracy.
  - If `AGENTS.md` or other `doc/` files are outdated or inaccurate, flag this and suggest how to keep them current and non-redundant
```

You may need to change the language in this command/skill to better fit
your project and needs. Part of the reflection process is to *only offer
documentation changes that will reduce future efforts*. More than half
the time I use this command, the agent does not offer any changes,
especially as my project and features begins to stabilize. I may also
not `/reflect` on every session, it just really depends what is being
worked on.

### The “Plan, Implement, Reflect” Workflow

The workflow and its supporting commands are also available (and likely
more up to date) on my [context_stash
repo](https://github.com/mjc-gh/context_stash/). This repo contains
various markdown files and scraps of text that I will use with agentic
development and LLMs and was inspired by comments made by
[Simon Willison on Lenny's Podcast](https://www.lennysnewsletter.com/p/an-ai-state-of-the-union).

While the specifics of this workflow may change over time, I think this
simple workflow will be applicable to agentic development for a while.

A lot of the steps in this process are not that far removed from Agile
methodologies that most professional developers are well acquainted
with. In particular, the idea of a “retro” is straight out of the Agile
playbook. Here, we’re just adapting these concepts to the agentic era,
where we can perform these workflows and rituals on a much shorter
timescale, from days and weeks to minutes and hours, with very small
teams or even as solo developers.
