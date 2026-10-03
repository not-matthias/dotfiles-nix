---
name: plain-prose
description: Use when writing or editing prose in chat replies, commit messages, PR descriptions, documentation, code comments, or design notes to remove LLM tells and write direct, concrete language.
---

# Plain prose

Adapted from [fzakaria/nix-home's writingStyle rules](https://github.com/fzakaria/nix-home/blob/master/users/fmzakari/agent-settings.nix#L61). The source draws on [Wikipedia's Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing) and [Simon Willison's LLM cliche highlighter](https://tools.simonwillison.net/llm-cliche-highlighter).

Apply these rules to prose. When a rule conflicts with clarity, choose clarity.

## Vocabulary

Avoid these words: delve, tapestry, meticulous, pivotal, intricate, interplay, underscore, garner, bolster, vibrant, bustling, multifaceted, seamless, commendable, ever-evolving, realm, landscape (figurative), testament, showcase, foster, harness (verb), unlock (figurative), elevate, embark, navigate (figurative), robust, crucial, essential, profound, nuanced, holistic, myriad, plethora, leverage (verb).

Avoid connective tics: "Additionally", "Moreover", "Furthermore", "In conclusion", "Overall", and "That said" as a paragraph opener.

## Constructions

- State the positive claim directly. Avoid "not just X, but Y", "not only X but also Y", and "it is not X - it is Y".
- Avoid "no X, no Y" chains such as "no config, no setup, no hassle".
- Delete didactic hedging: "it is important to note that", "it is worth noting", "it should be noted", and "keep in mind that". State what matters.
- Avoid puffery: "stands as a testament to", "plays a crucial role in", "marks a pivotal moment", "leaves an indelible mark", "rich history", "hidden gem", "nestled in", "in the heart of", and "boasts".
- Avoid participle tails such as ", highlighting the ...", ", underscoring its ...", ", showcasing ...", ", reflecting the ...", and ", demonstrating ...". Remove invented commentary.
- Cite a specific source or drop the claim. Avoid "experts argue", "studies show", "observers have noted", and "industry reports indicate".
- Avoid challenges-and-outlook boilerplate: "despite these challenges", "challenges remain", "it remains to be seen", and "only time will tell".
- Avoid stage-managed reveals: "here is the thing", "here is the twist", "here is the catch", "turns out ...", "the punchline is", and "plot twist".
- Be honest without announcing it. Avoid "to be honest", "let me be clear", "honestly", "look", and "I will not pretend".
- Avoid therapy voice: "sit with that", "that is not nothing", "worth naming", "you already know the answer", and "that is valid".
- Avoid superlative narrowing: "that is the whole point", "that is the entire game", "the only X I trust", and "that is the part that matters".
- Avoid obituary headlines: "X is dead" and "long live X".
- Avoid dev-blog boilerplate: "it just works", "batteries included", "zero config", "sane defaults", "from the ground up", "first-class citizen", "game changer", and "under the hood" unless literally about a car.
- Avoid stacks of rhetorical questions followed by your own answers.
- Vary sentence structure. Avoid consecutive sentences with the same frame or three sentences starting with the same word.
- Do not pad lists to three items for rhythm.
- Avoid a colon introducing a triple when the sentence works without it.

## Formatting

- Use no emoji unless the user used one first.
- Reserve bold for genuine labels, used sparingly.
- Use sentence case for headings.
- Use straight quotes and apostrophes.
- Use em dashes rarely, at most one per paragraph.
- Use prose by default. Use lists for actual lists, not to break prose into noun phrases.
- Omit opening paragraphs that restate the request and closing summaries that repeat the answer.

## Revision

Write short declarative sentences. Use concrete nouns and specific numbers. Name what happened and what it means for the reader. State what you do not know rather than hiding uncertainty with confident filler.

Before sending, remove banned phrases, unsupported claims, repeated sentence frames, and unnecessary commentary. Preserve technical terms, quotations, and facts when rewriting would change their meaning.
