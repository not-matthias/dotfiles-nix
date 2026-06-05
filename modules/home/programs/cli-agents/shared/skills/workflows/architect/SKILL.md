---
name: architect
description: Full technical architect toolkit for pre-implementation due diligence. Covers prior art research, codebase impact analysis, design doc / RFC generation, acceptance criteria, and dependency mapping. Use when the user wants to do technical planning, architecture review, impact analysis, or due diligence before building. Triggers on /architect, "what's the impact of", "write an RFC", "design doc for", "what exists for this", "prior art", "acceptance criteria", "what would this affect".
---

# Architect

Technical architect toolkit that performs the due diligence an experienced architect/PM would do before committing to an implementation.

## What This Skill Produces

A standalone architecture document saved to `.agents/docs/` containing:
1. **Prior art research** — What already exists for this problem
2. **Impact analysis** — What in the codebase this change would affect
3. **Design document / RFC** — Formal proposal with alternatives considered
4. **Acceptance criteria** — Concrete "done when" definitions
5. **Dependency map** — What blocks what, critical path, spikes needed

## Workflow

### Phase 1: Understand the Input

The input can be:
- A raw idea ("I want to add caching to the API")
- A brainstorm plan (from /brainstorm or a doc in .agents/docs/)
- A specific technical question ("Should we use Redis or Memcached?")

If the input is vague, ask 2-3 clarifying questions using **AskUserQuestion** with concrete suggestions. Don't over-ask — this skill is about analysis, not discovery (that's /brainstorm's job).

### Phase 2: Prior Art Research

Search for existing solutions before designing a new one.

**Default (quick survey):**
1. Search GitHub for existing implementations (use `gh search repos` and `gh search code`)
2. Web search for established solutions, libraries, and patterns
3. Summarize top 3-5 results with links, maturity, and relevance

**Go deeper when:**
- The quick survey reveals the problem is already well-solved
- The user explicitly asks for thorough analysis
- License compatibility matters

**Output format:**
```markdown
## Prior Art

| Solution | Type | Maturity | Notes |
|----------|------|----------|-------|
| [name](link) | library/tool/pattern | active/maintained/abandoned | key tradeoff |

**Recommendation:** Use X / Build custom because Y / Adapt Z
```

### Phase 3: Impact Analysis (Codebase-Aware)

For changes to existing codebases, map the blast radius by actually reading the code.

1. **Grep for affected areas** — Search for functions, modules, types, and APIs that would be touched
2. **Trace dependencies** — What imports/calls the affected code? What would break?
3. **Identify data model changes** — Schema migrations, config changes, API contract changes
4. **List affected files** — Concrete file paths with brief description of what changes

**Output format:**
```markdown
## Impact Analysis

### Directly Affected
- `path/to/file.rs:42` — Function X needs to change because...
- `path/to/schema.sql` — New column needed for...

### Indirectly Affected
- `path/to/consumer.rs` — Calls the modified function, may need updating
- `tests/test_feature.rs` — Tests will break, need updating

### Data / Migration Impact
- Database migration required: yes/no
- Config changes: yes/no
- API breaking change: yes/no
```

For greenfield projects or non-code topics, do a conceptual impact analysis instead (what systems, teams, or processes would be affected).

### Phase 4: Design Document / RFC

Write a concise design document. This is for review — it should be clear enough that someone who wasn't in the brainstorm can understand and critique it.

```markdown
## Design

### Problem Statement
One paragraph: what problem are we solving and why now.

### Proposed Solution
Description of the chosen approach. Include diagrams (mermaid) when they clarify architecture or data flow.

### Alternatives Considered
| Alternative | Why Not |
|-------------|---------|
| Approach A | Tradeoff reason |
| Approach B | Tradeoff reason |

### Key Design Decisions
- **Decision 1**: Chose X over Y because Z
- **Decision 2**: ...
(Only non-obvious decisions. Skip self-evident choices.)
```

### Phase 5: Acceptance Criteria

Define concrete, testable "done when" statements.

```markdown
## Acceptance Criteria

- [ ] Users can [specific action] and see [specific result]
- [ ] Performance: [specific metric] under [specific conditions]
- [ ] Error case: When [condition], the system [behavior]
- [ ] Existing [feature/test] still works unchanged
```

Guidelines:
- Each criterion must be verifiable (testable or demonstrable)
- Include happy path, error cases, and edge cases
- Include non-functional requirements when relevant (performance, security, accessibility)
- Keep the list to 5-10 criteria. If you need more, the scope is probably too big.

### Phase 6: Dependency Map

Identify what blocks what and what order things should happen in.

```markdown
## Dependencies & Sequencing

### Critical Path
1. [First thing that must happen] — blocks everything else
2. [Next thing] — depends on #1
3. ...

### Spikes / Unknowns
- [ ] **Spike: [question]** — Need to verify [assumption] before committing to [decision]. Estimated effort: [small/medium].

### External Dependencies
- [Team/service/API] — Need [what] from them by [when/before what]
```

### Phase 7: Save

Assemble all sections into a single document and save to `.agents/docs/YYYY-MM-DD-architect-<slug>.md`.

Tell the user where the file was saved and give a 2-3 sentence summary.

## Rules

- **Actually read the code.** Impact analysis based on guesses is worse than no impact analysis. Grep, read files, trace dependencies.
- **Be opinionated.** When prior art research reveals a clear winner, say so. Don't present 5 options as equally valid when they're not.
- **Skip sections that don't apply.** Greenfield project? No impact analysis needed. Simple feature? Dependency map might be overkill. Use judgment.
- **Keep it concise.** The document should be skimmable in 2-3 minutes. If a section is getting long, you're going too deep.
- **Use AskUserQuestion** for any clarifying questions, always with concrete suggestions.
- **Link to files.** When referencing code, use `path/to/file.rs:line` format so the reader can jump there.
- **Mermaid diagrams** are encouraged for architecture, data flow, and dependency visualization — but only when they add clarity over a text description.
