---
name: writing-style
description: "Emulates not-matthias's technical blog writing style. Use when writing blog posts, technical articles, README content, or any long-form technical prose. Produces investigation-driven, first-person narratives with dry humor, practical code examples, and concrete takeaways."
---

# Writing Style Skill

Emulates the technical writing voice of not-matthias — a systems programmer who writes investigation-driven blog posts about Rust, reverse engineering, performance, and security.

## When to Use This Skill

- Writing new blog posts or technical articles
- Drafting README content or project documentation with personality
- Editing or rewriting technical prose to match this voice
- Writing company blog posts (slightly more polished but same core voice)

## Voice & Tone

### Core Identity

The voice is a **curious engineer narrating an investigation in real-time**. You are in the trenches — debugging, benchmarking, reversing, building — and you're bringing the reader along.

Key traits:
- **Curious and mischievous**: You poke at systems because it's fun. Reverse engineering a party jukebox, automating Discord achievements, chasing a -1 homework penalty down a 3-hour rabbit hole — these are all valid reasons to write thousands of words.
- **Pragmatic and results-oriented**: Even when playful, you always return to concrete findings, measurements, or implementation decisions.
- **Honest about the process**: You share what failed, what confused you, what drove you insane. The messiness is part of the story.

### Formality Level

Informal technical. Conversational prose with casual interjections, but the technical content is precise. Readers are assumed to be technical peers who enjoy deep dives.

### Humor Style

Dry, self-deprecating, and occasionally absurdist. Humor is used as pacing — a breather between dense technical sections, never constant.

Patterns:
- Comedic understatement to justify unnecessary-but-fun work: "So I did the only logical thing" / "So I did the only reasonable thing: Automate it."
- Self-aware acknowledgment of rabbit holes: "Did I really just spend 3 hours writing this blog post because of -1 point out of 24? Maybe."
- Mock-corporate satire: "state-of-the-art military-grade quantum-proof AI encrypted CDN™"
- Blunt self-criticism across time: "I want to ask the version of me from 3 years ago: Why the hell did you use a monospace font for the text?"

### What to Avoid

- Flattery or sycophantic tone
- Promotional language or hype
- Em dash overuse (use sparingly if at all)
- Words like "pivotal", "landscape", "innovative", "comprehensive", "leverage"
- Exclamation marks (except rare genuine excitement like "Let's find out!" or emoji-reactions like 🔥 used very sparingly)
- Starting sentences with "Interestingly" or "Importantly"

## Article Structure

### Opening / Hook

Always open with a **personal trigger** — never an abstract thesis statement. The reader should immediately understand *why you care*.

Common patterns (pick one per article):
1. **Personal context**: "I'm currently working on an Intel hypervisor (very fun project btw) and had the following problem..."
2. **Story cold-open**: Drop the reader into a scene. "A while ago while I was partying at a silent disco bar, I noticed something interesting..."
3. **Small grievance that escalates**: "It was a nice monday evening, and I decided to take a look at the feedback of my university homeworks."
4. **Time-skip update**: "A lot has changed since I wrote my first blog post on..."
5. **Surprising observation**: "At CodSpeed we sometimes get reports that benchmarks regressed when making seemingly unrelated code changes."

The hook should establish the question or mystery within the first 1-3 paragraphs. State the goal as a curiosity you're about to test, not as a conclusion you'll prove.

### Body: The Investigation Loop

The body follows a **narrative debugging structure** — a tight loop of:

1. **Hypothesis** → "My first assumption was..."
2. **Experiment** → "Let's benchmark it" / "I tried..."
3. **Result** → Present data, code, output
4. **Pivot** → "Turns out..." / "But can we do better?" / "That didn't help, so..."
5. **Repeat** with a new hypothesis

This creates a story-shaped technical document. The reader experiences the discovery alongside you.

### Section Headers

- Descriptive and utilitarian, occasionally playful
- Use H2 (`##`) for major investigation phases
- Use H3 (`###`) for sub-experiments, alternatives, or breakdowns
- Imply progression: the headers should read like a table of contents of a debugging session
- Examples: "How does it work?", "Reverse Engineering it", "Hitting the jackpot", "Why is GLIBC faster on different machines?", "How to fix it?"

### Conclusions

End with **both** concrete takeaways and a reflective/witty closing:

1. **Practical takeaways**: What to use, what to avoid, what matters. Often as a short bulleted list or bold statements.
2. **Reflective punchline**: Self-aware humor, a life philosophy moment, or a callback to the opening.
3. **Soft reader engagement**: "If you have any comments, feel free to reach out" / "As always, thanks for reading!" / Ask for feedback naturally.

Never end with a generic summary paragraph that restates everything. The conclusion should feel like a natural stopping point, not a recap.

## Sentence & Paragraph Patterns

### Sentence Rhythm

Alternate between short punchy lines and longer explanatory sentences. Short lines deliver humor, pivots, or emphasis. Longer sentences carry technical detail.

**Short sentences for impact:**
- "Not bad."
- "All binaries have the same hash!"
- "This was only a small project, but we still learned quite a lot."
- "Turns out, it doesn't matter which crate or option we choose."

**Longer sentences for explanation:**
- "Since it's a web app, the first thing I looked at was the network requests."
- "I wasn't sure what this comment was referring to, so I had to look it up (thankfully they added the line numbers)."

### Paragraph Length

Short-to-medium (2-5 sentences). Break up dense topics with:
- Single-sentence paragraphs for emphasis or comedic timing
- Code blocks as natural paragraph breaks
- Tables for comparison data
- CLI output for evidence

### Transition Phrases

These are signature connectors — use them naturally throughout:
- **"Turns out..."** — The most characteristic phrase. Used when reality violates expectation.
- **"But can we do better?"** — Signals iteration to a new approach.
- **"Let's find out!"** — Invites the reader into the next experiment.
- **"So I did the only logical/reasonable thing..."** — Comedic justification before doing something unnecessary-but-fun.
- **"Almost out of ideas, I..."** — Honest process narration before a breakthrough.
- **"This bug was driving me insane"** — Expressing genuine frustration.
- **"That didn't help, so..."** / **"Since none of my fixes worked..."** — Failed-attempt transitions.
- **"Here's what I think is happening:"** — Hypothesis framing.

Also common: Starting sentences with "So", "But", "Now", "Since", "After", "Yet", "At this point".

## Technical Explanation Style

### Just-In-Time Theory

Never front-load textbook content. Introduce concepts exactly when the narrative demands them. If you need to explain memory ordering, do it when atomics enter the caching story — not before.

### Concrete First

Start from a real bug, goal, or observation. Derive the conceptual explanation from the concrete situation, not the other way around.

### Preserve the Surprise

Set an expectation → reveal that reality violated it → explain why. This is the core pedagogical pattern.

Example flow:
1. "You might think: 'Wait, why do we need to load the value again?'"
2. Present the surprising behavior
3. "The reason is that..."

### Depth Calibration

- Explain concepts when they're the critical point of the article
- Drop technical nouns (CDN, bytecode, atomics, ASLR) without over-explaining when they're not the focus
- For tangential but interesting topics, add a brief parenthetical or link: "If you want to learn more about it, I can recommend..."

## Code Integration

### Code as Evidence

Code blocks serve as evidence and instrumentation, not decoration. Every code block should be directly tied to:
- An experiment ("here's the version I tested")
- A technique ("how to parse this")
- A proof ("this is the protocol detail")
- A comparison ("here's the before/after")

### Before Code Blocks

Always include a brief setup sentence explaining:
- What this snippet is for
- What to look for in it
- Why it's the minimal reproduction

Examples:
- "The decompiled code from above looks like this:"
- "We can compare this across all runs, to see how they differ:"
- "My implementation has 2 different types:"
- "The solution is quite straightforward, but how does it perform?"

### After Code Blocks

Follow with immediate interpretation:
- "Looks pretty similar, huh?"
- "Not bad. It takes on average around 215ps to get the value."
- "If you take a close look at the table, you can see that Run 5 seems different."
- "After decrypting the binary blob, we'll finally have a PE image"

Then iterate to the next step: "Okay, but..." / "So I changed..." / "But can we do better?"

### Data Presentation

Use tables for comparison data (benchmark results, CPU features, cache sizes). Use CLI output blocks for tool results (jq, hexyl, sha1sum, lscpu). Mix formats naturally.

## Reader Engagement

### Direct Address

Use "you" sparingly but effectively:
- "Can you spot it?"
- "If you haven't noticed yet..."
- "You might have guessed it."
- "Don't worry if you didn't understand everything, that's not the focus."

### "Let's" as Co-Investigation

Use "let's" to invite the reader along:
- "Let's benchmark it"
- "Let's find out!"
- "Let's take a step back."
- "Let's check out another equally popular crate"

### Reader as Peer

Treat the reader as a technical peer. Give enough detail to reproduce or extend. Never talk down.

## Self-Reference Patterns

### Process Transparency

Share what you tried, what you believed, how you got stuck, and how you unstuck yourself:
- "I tried so many different things that didn't work: [list]"
- "After none of my fixes worked, I decided to consult the Rust Nomicon."
- "Not knowing where to continue, I wanted to try one more thing."
- "While checking the execution order in our logs by diffing them, I noticed something very interesting"

### Cross-Referencing Own Work

Reference previous blog posts or projects naturally:
- "When I originally wrote [Kernel Printing with Rust]..."
- "A lot has changed since I wrote my first blog post on..."

### Blunt Self-Criticism

Be honest about past mistakes or questionable decisions. Don't hedge — own it with humor.

## Links & References

### How to Introduce Links

Links are practical pointers or supporting evidence, not academic citations:
- "Luckily, some people have already reverse engineered it and documented some parts."
- "I can recommend the video [Crust of Rust: Atomics and Memory Ordering] by Jon Gjengset"
- "I found [this] Stackoverflow post, which showed..."
- "You can find the benchmarks [here]."

### External Resources

When referencing tools, crates, or documentation, briefly explain why it matters in context rather than just dropping a link.

## Company Blog Adaptation

When writing for a company blog (e.g., CodSpeed), adjust slightly:
- More polished structure with clearer section progression
- Use "we" instead of "I" when representing the company
- Include more structured data (tables, figures with captions)
- Keep the investigation narrative and characteristic phrases
- Slightly reduce self-deprecating humor
- Add context that external readers might need
- Still use "Turns out...", rhetorical questions, and the hypothesis-experiment loop

## Signature Sentence Templates

Use these patterns naturally — don't force all of them into every article:

- "As programmers, our mental model has been trained to think in abstractions."
- "[X] is quite [adjective], but what if [complication]? This would [consequence]. Let's see if we can do better."
- "You might think: '[reasonable assumption]'. The reason is that [surprising reality]."
- "Since I have [relevant experience], I assumed that [expectation]. I couldn't have been more wrong."
- "After all, it is never a waste of time to learn something new."
- "I actually really like this change."
- "I really enjoyed working on this [project/benchmark/investigation]."
- "This was a fun project and I learned a lot about [topic]."
- "As always, thanks for reading!"
