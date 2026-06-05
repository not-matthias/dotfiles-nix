---
name: brainstorm
description: Interactive brainstorming and planning skill. Use when the user wants to brainstorm, plan, spec out, or think through an idea — whether it's a software feature, a project, a business idea, or anything else. Triggers on /brainstorm, "let's brainstorm", "help me plan", "spec this out", "I want to build X but not sure how", "help me think through", "design X with me". Asks structured questions in adaptive rounds, explores the codebase when relevant, and produces a plan with task breakdown saved to .agents/docs/.
---

# Brainstorm

Interactive brainstorming skill that turns a vague idea into a concrete, actionable plan through structured questioning.

## Workflow

### Phase 1: Understand the Topic

Read the user's initial prompt carefully. Determine:
- **Domain**: Is this about code in the current project, a new project, a non-technical idea, or something else?
- **Clarity level**: How well-defined is the idea already? A one-liner needs more discovery than a detailed brief.

If the topic relates to the current codebase, explore relevant files first (architecture, existing patterns, related modules) so your questions are grounded in reality, not generic.

### Phase 2: Ask Questions in Adaptive Rounds

Ask questions using the **AskUserQuestion** tool. Each round should have 3-5 questions max (respecting the tool's 4-question limit per call — use two calls if needed for 5 questions).

#### Round 1: Scope and Goals
Establish the big picture. Example areas to cover:
- What is the core goal / problem being solved?
- Who is this for? (Users, team, self)
- What does success look like?
- What's the rough scope? (MVP, full feature, exploration)
- Are there any hard constraints? (Tech stack, timeline, budget, compatibility)

#### Round 2+: Drill Into Gaps
Based on Round 1 answers, identify areas that need more clarity. Each follow-up round should:
1. Briefly summarize what's been established so far (1-2 sentences, not a wall of text)
2. Ask about the gaps that remain

Common follow-up areas:
- **Technical approach**: Architecture, data model, API design, storage
- **Behavior details**: Edge cases, error handling, user flows
- **Integration**: How does this fit with existing systems/code?
- **Prioritization**: What's must-have vs nice-to-have?
- **Non-obvious decisions**: Things the user might not have considered

Stop asking when:
- All major decisions are covered
- Remaining unknowns are implementation details (figure out during coding)
- You've done 2-4 rounds (avoid fatigue — 3 rounds is typical)

#### Question Quality Guidelines

Every question MUST include concrete suggestions as options. Never ask a bare open-ended question.

**Good**: "Where should we store user preferences?" with options like:
- SQLite database (simple, local, no server needed)
- JSON file in ~/.config/ (XDG standard, human-editable)
- Cloud sync via existing API (if you have one)

**Bad**: "How do you want to handle storage?"

When creating options:
- Lead with the recommended option when you have a clear opinion
- Include 2-4 options per question (the tool enforces this)
- Each option needs a short label AND a description explaining tradeoffs
- Use previews (the tool's preview field) when comparing code approaches, UI layouts, or architecture diagrams
- There's always an implicit "Other" option, so don't waste a slot on it

### Phase 3: API / Code Design (Code-Related Topics Only)

If the brainstorm is about a software feature, enter an iterative design phase before generating the final plan. Skip this phase entirely for non-code topics.

#### How It Works

1. **Propose 2-3 design options** using AskUserQuestion with code previews. Each option should show concrete code: function signatures, type definitions, data structures, API endpoints, or module interfaces — whatever is most relevant.

2. **The user picks and refines.** They might pick one option, mix parts from different options, or say "none of these, try X instead."

3. **Iterate.** Update the design based on feedback, present the revised version. Ask if anything else needs changing. Repeat until the user is satisfied.

4. **Lock it in.** Once approved, the design becomes part of the plan document.

#### What to Show in Previews

Use the AskUserQuestion `preview` field to show actual code. Match the language the project uses.

Examples of what to sketch:
- **API endpoints**: Route definitions, request/response shapes
- **Type definitions**: Structs, enums, interfaces
- **Function signatures**: Public API surface with argument types and return types
- **Module structure**: Which files/modules exist and what each is responsible for
- **Data model**: Schema, relationships, key fields

#### Guidelines

- Keep sketches rough — just the shape, not the implementation. No function bodies unless the logic IS the design decision.
- When options differ meaningfully, highlight what's different in each description. Don't make the user diff code blocks mentally.
- 1-3 iteration rounds is typical. If it's going past 3, the scope might be too big — suggest splitting.
- If the user says "looks good" or "let's go with this", stop iterating and move to the plan.

### Phase 4: Generate the Plan

After all rounds (and optional design iteration) are complete, produce a plan document with the following structure:

```markdown
# [Plan Title]

> One-sentence summary of what this plan covers.

## Goal
What we're building/doing and why.

## Scope
What's in scope and what's explicitly out of scope.

## Approach
High-level description of the chosen approach. For complex decisions, briefly note why this approach was chosen over alternatives.

## Design Decisions
Key decisions made during brainstorming, with brief rationale for each.
(Only include non-obvious decisions — skip anything self-evident.)

## API / Code Design
(Include ONLY for code-related brainstorms. Contains the agreed-upon code sketch from Phase 3.)
The finalized type definitions, function signatures, API shape, or module structure.

## Tasks
Ordered implementation checklist. Each task should be concrete and actionable.

- [ ] Task 1: Description
- [ ] Task 2: Description
- [ ] ...

## Risks and Open Questions
(Include this section ONLY if the brainstorm revealed significant uncertainty, unknowns, or risks. Omit for straightforward plans.)
```

### Phase 5: Save

Save the plan to `.agents/docs/YYYY-MM-DD-<slug>.md` using today's date and a short kebab-case slug derived from the plan title.

Tell the user where the file was saved and give a brief summary of the plan.

## Rules

- **Always use AskUserQuestion** for questions. Never dump questions as plain text.
- **Always include concrete suggestions** as options. Ground them in the project context when possible.
- **Don't over-ask.** 2-4 rounds is the sweet spot. If the user's initial prompt is already detailed, you might only need 1-2 rounds.
- **Don't repeat back everything the user said.** Brief summaries between rounds to confirm direction, not exhaustive recaps.
- **Adapt the number of options to complexity.** Simple yes/no decisions → 2 options. Complex architectural choices → 3-4 options with tradeoffs.
- **Explore the codebase first** when the brainstorm is about the current project. Your questions should reference actual file paths, existing patterns, and real constraints.
- **Keep the plan concise.** A plan that's too long to skim is a plan nobody reads. Prefer bullet points over paragraphs.
