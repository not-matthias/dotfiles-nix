---
name: humanizer
description: Identifies and removes AI-generated text patterns. Detects inflated symbolism, promotional language, superficial analyses, vague attributions, em dash overuse, and AI vocabulary. Adds personality through opinions, varied rhythm, complexity acknowledgment, and specific details.
license: MIT
---

<!-- Source: https://github.com/blader/humanizer/raw/refs/heads/main/SKILL.md -->

# Humanizer Skill

Humanizer is a writing editor tool that identifies and removes AI-generated text patterns, making writing sound more natural and human-authored.

## When to Use This Skill

- When user asks to improve or humanize their writing
- When reviewing text that sounds robotic, formulaic, or AI-generated
- When user mentions they want writing to feel more natural or authentic
- When identifying specific patterns like overused phrases, excessive em dashes, or vague claims
- When user wants to add personality and authenticity to content

## Detectable AI Patterns

The humanizer identifies 24+ documented patterns across four categories:

### Content Patterns
- **Inflated symbolism**: Overemphasis on significance or notability claims
- **Promotional language**: Phrases that sound like marketing copy
- **Formulaic "challenges" sections**: Templated problem-statement structures
- **Undue emphasis**: Exaggerated importance claims that lack grounding

### Language Patterns
- **AI vocabulary**: Overused words like "additionally," "pivotal," "landscape," "innovative"
- **Copula avoidance**: Awkward phrasing like "serves as" or "stands as" instead of "is"
- **Excessive hedging**: Unnecessary qualifications and disclaimer language
- **Vague attributions**: Phrases like "it is said that" without specific sources

### Style Patterns
- **Em dash overuse**: Excessive use of — for emphasis or parenthetical asides
- **Unnecessary boldface**: Overuse of **emphasis** that signals AI formatting
- **Emoji decoration**: Misplaced or gratuitous emoji use
- **Title case in headings**: Inconsistent or overly formal capitalization

### Communication Patterns
- **Chatbot artifacts**: Phrases like "I hope this helps" or "feel free to ask"
- **Knowledge-cutoff disclaimers**: Unnecessary caveats about AI limitations
- **Sycophantic tone**: Excessive politeness or self-deprecation
- **Negative parallelism**: Patterns like "not X, not Y, not Z" structures

## Humanization Workflow

### Step 1: Identify Problem Patterns
Review the text for common AI-generated patterns listed above. Note which categories appear most frequently.

### Step 2: Remove Obvious Patterns
- Replace overused AI vocabulary with simpler, more natural alternatives
- Cut excessive em dashes and replace with periods or commas
- Remove disclaimer language and hedging qualifiers
- Delete chatbot pleasantries

### Step 3: Add Personality
The critical step beyond pattern removal. Good humanization requires:
- **Opinions**: Express clear viewpoints rather than staying neutral
- **Varied sentence rhythm**: Mix short, punchy sentences with longer ones
- **Complexity acknowledgment**: Admit nuance, trade-offs, and uncertainty
- **Specific details**: Replace vague claims with concrete examples and data

### Step 4: Validate
Read the result aloud to check for:
- Natural flow and conversational tone
- Absence of remaining formulaic patterns
- Presence of authentic voice and perspective
- Balance between confidence and honest uncertainty

## Examples

### Example 1: Content Pattern Fix

**Before (AI-generated):**
"This pivotal innovation represents a significant paradigm shift in the landscape of modern development, fundamentally addressing previously unforeseen challenges."

**After (Humanized):**
"This tool changed how we approach development by solving three concrete problems we struggled with for years."

### Example 2: Language Pattern Fix

**Before (AI-generated):**
"The framework serves as a comprehensive solution that stands as an industry-leading approach to data processing."

**After (Humanized):**
"The framework handles data processing efficiently. It outperforms most alternatives in our benchmarks."

### Example 3: Style Pattern Fix

**Before (AI-generated):**
"Key Benefits — Improved Performance — Reduced Costs — Enhanced Scalability"

**After (Humanized):**
"Key benefits: faster performance, lower costs, better scalability."

### Example 4: Communication Pattern Fix

**Before (AI-generated):**
"I hope this helps! Feel free to reach out if you have any questions. As an AI, my knowledge cutoff is April 2024, so please verify recent information."

**After (Humanized):**
"Let me know if you need clarification or have follow-up questions."

## Common Issues

**Issue: Text becomes too casual or unprofessional**
- **Solution**: Maintain formality appropriate to context while removing AI patterns. Professional ≠ robotic.

**Issue: Removed patterns but writing still feels flat**
- **Solution**: You must add personality. Add opinions, specific examples, or acknowledgment of complexity—pattern removal alone isn't enough.

**Issue: Unsure which patterns apply**
- **Solution**: Read text aloud. AI-generated text has a distinctive rhythm and tone even if individual patterns aren't obvious.

**Issue: Over-correcting and losing clarity**
- **Solution**: Balance humanization with readability. Some AI patterns exist for clarity reasons; preserve those while removing stylistic ones.

## Tips and Best Practices

1. **Read aloud**: AI text has a detectable rhythm. Reading aloud helps identify patterns you might miss visually.

2. **Preserve structure but reshape language**: Don't rewrite the entire piece—identify and fix the specific patterns while keeping the core message.

3. **Add one personality element per section**: Instead of trying to add personality everywhere, focus on one section and add specific details, opinions, or acknowledgment of complexity.

4. **Compare drafts**: Highlight the differences between your AI-generated version and the humanized version. This trains your eye for patterns.

5. **Watch for pattern clusters**: If you find one AI pattern (like "additionally"), scan for others nearby. AI-generated text often clusters patterns.

6. **Use this for revision, not initial writing**: Humanizer works best when editing existing text, not as guidance for initial composition.

7. **Remember the core principle**: Good writing is specific, opinionated, and acknowledges complexity. If your humanized text lacks these, add them—pattern removal alone won't create authentic writing.
