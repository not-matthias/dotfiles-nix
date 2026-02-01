---
name: fact-checker
description: Systematic fact-checking for technical blog posts. Extracts every claim (explicit and implicit), cross-references against attached specifications, architecture manuals, source code, and documentation, then generates a verification report with citations and verdicts.
license: MIT
---

<!-- Source: https://github.com/0avx/claude-skills/blob/main/fact-checker.md -->

# Technical Content Fact-Checking Skill

## Overview

This skill enables rigorous, systematic fact-checking of technical blog posts, tutorials, documentation, and technical writing. The scope encompasses all technical content: software APIs and libraries, CPU architecture and instruction sets, operating system internals, memory models, hardware interfaces, protocols, and systems programming.

The goal is **exhaustive verification** of every claim against authoritative technical sources—with attached specifications, architecture manuals, source code, and documentation serving as the primary source of truth.

Technical content is uniquely dangerous when inaccurate. A misstatement about register behavior, a wrong description of a system call, an incorrect memory ordering guarantee, or a flawed explanation of cache coherency can cause readers to write subtly broken code, introduce security vulnerabilities, or develop fundamentally wrong mental models. The stakes demand rigor.

## Core Principles

1. **Specifications Are Truth**: When a technical specification is attached—whether an API reference, architecture manual, or kernel documentation—it is the authoritative source. The article must conform to the spec, not the other way around.
2. **Exhaustive Extraction**: Every technical claim—explicit statements and implicit assumptions—must be identified and verified.
3. **Cross-Reference Everything**: Each claim must be traced back to its authoritative source with exact citations.
4. **Implicit Claims Matter Most**: The assumptions an author doesn't realize they're making are often where errors hide.
5. **Precision Over Generosity**: In technical writing, "close enough" is wrong. An instruction that sets flags is not equivalent to one that preserves them. A syscall that returns `-EINVAL` is not the same as one that returns `-EFAULT`.

## Phase 1: Technical Claim Extraction

### 1.1 The Technical Reader's Mindset

Technical content is dense with claims. A single sentence describing a CPU instruction might contain half a dozen verifiable assertions: the mnemonic, its operands, their allowed sizes, the encoding, affected flags, and exception conditions. A paragraph about virtual memory might implicitly assert page sizes, permission models, and hardware capabilities. Your job is to see all of them.

Read like a machine, not a human. Humans skim and infer; machines execute exactly what is specified. When an article says "the processor fetches the next instruction," a human understands the general idea. A rigorous reader sees claims: there is a fetch stage, it operates on instructions, there is a concept of "next" implying sequential execution or a specific fetch policy. Each of these can be wrong or misleading in context.

Assume nothing is obvious. Technical writers often omit details they consider "obvious" or "standard." These omissions are implicit claims about defaults, behaviors, and invariants that may or may not be accurate. When an article doesn't specify the processor mode, it's implicitly claiming the discussion applies universally or that the default is obvious. When it doesn't mention atomicity, it's implicitly claiming either atomic behavior or that atomicity doesn't matter.

### 1.2 Categories of Technical Claims

Technical content contains claims across multiple dimensions. You must extract all of them:

**Naming and Identification**
Any reference to a specific name: instruction mnemonics, register names, system calls, kernel functions, data structures, configuration parameters, signal names, error codes, hardware components. Names must be exact. Case sensitivity varies by domain but precision is always required.

**Encoding and Representation**
How things are represented in bits, bytes, and data structures: instruction encodings, data layout, endianness, alignment requirements, field positions within structures, bit flags and masks, numeric representations. Every element of an encoding is a separate verifiable claim.

**Behavior and Semantics**
What happens when something executes or is invoked: what an instruction does to architectural state, what a system call modifies, what side effects occur, what state transitions happen, what ordering guarantees apply. Behavioral claims are often the most error-prone because they require understanding implementation details, not just interfaces.

**Microarchitectural Claims**
Claims about how hardware implements architectural guarantees: pipeline stages, cache behavior, branch prediction, out-of-order execution, speculative execution, memory hierarchies. These claims are particularly treacherous because microarchitecture varies across implementations and generations.

**Memory Model and Ordering**
Claims about memory visibility, ordering guarantees, synchronization requirements, cache coherency, memory barriers, atomic operations. Memory model claims are notoriously subtle and frequently wrong.

**Privilege and Protection**
Claims about privilege levels, protection rings, capability requirements, permission checks, security boundaries, isolation guarantees. Errors here can have security implications.

**Sequencing and Dependencies**
The order in which things must happen: initialization sequences, dependency chains, protocol handshakes, synchronization requirements. Sequencing claims are often implicit—present only in the order of description or code examples.

**Conditions and Constraints**
Requirements, prerequisites, limitations: hardware requirements, alignment constraints, size limits, timing requirements, valid input ranges, architectural limits. These are frequently outdated or incorrectly transcribed.

**Defaults and Implicit State**
What state exists when not explicitly set: default register values, initial memory contents, default configuration, implicit flags. Defaults vary across architectures, operating systems, and versions.

**Exception and Error Conditions**
What can go wrong: fault types, exception vectors, error returns, undefined behavior conditions, architectural violations. Authors often describe the normal path and make implicit claims about error handling.

**Performance and Timing Characteristics**
Latencies, throughputs, cycle counts, complexity bounds. Performance claims require empirical evidence or architectural specification; they vary across implementations and should not be assumed stable.

**Compatibility and Evolution**
What features exist across architecture versions, backward compatibility guarantees, deprecated features, implementation-defined behavior. Compatibility claims require careful attention to specific versions and variants.

### 1.3 Extracting Implicit Claims

Implicit claims are the assertions an author makes without realizing they're making them. They hide in:

**Omissions**: What the article doesn't say. If an article describes an instruction without mentioning flag effects, it implicitly claims either that flags are unaffected or that flag behavior doesn't matter for the use case. If it describes a kernel interface without mentioning error returns, it implicitly claims success or that errors are handled elsewhere.

**Examples and Code**: Technical examples make dozens of implicit claims. Every register used implies it's available in that context. Every instruction sequence implies it's valid and sufficient. Every memory access implies the address is valid and properly aligned. Every syscall implies the process has appropriate privileges. Parse examples element by element.

**Generalizations**: Words like "always," "never," "all," "any," "guaranteed" are implicit claims about universal behavior. "The processor always preserves this register" claims there are no exceptions. "Any address can be used" claims there are no alignment or canonical form requirements.

**Assumed Context**: Articles assume a processor mode, an operating system, a privilege level, a configuration state. These assumptions are implicit claims that may not hold universally.

**Causal and Mechanistic Language**: "This causes," "this triggers," "this prevents," "this guarantees" are claims about causation and mechanism that may be incorrect, incomplete, or implementation-dependent.

**Temporal Claims**: "Now," "currently," "since version X," "in modern processors" are claims that may have been true when written but are now outdated, or that may not apply to all implementations.

**Scope and Applicability**: When an article discusses "x86" behavior, is it claiming this applies to all x86 processors? 32-bit and 64-bit? Intel and AMD? All generations? The scope of applicability is often an implicit claim.

For every explicit claim you extract, ask: "What is this claim assuming? What must be true for this claim to be valid? What context is being taken for granted?" Those assumptions are themselves claims requiring verification.

### 1.4 The Extraction Process

**First pass—explicit claims**: Read the article linearly and extract every explicit technical assertion. Be literal. If the article says a register is 64 bits wide, you extract that as a verifiable claim. If it says an instruction takes two operands, that's a claim. If it says a syscall returns a file descriptor, that's a claim about both the return type and the semantic meaning.

**Second pass—artifact analysis**: Examine every code example, assembly listing, structure definition, diagram, and technical artifact. Parse them syntactically. Extract claims from: instruction opcodes, register references, memory operands, addressing modes, immediate values, structure field definitions, bit field layouts, pseudocode operations.

**Third pass—implicit claims**: Re-read the article asking "what is being assumed here?" at each paragraph. Look for omissions, defaults, generalizations, and unstated prerequisites. What processor mode? What privilege level? What OS? What version? What configuration?

**Fourth pass—cross-reference setup**: For each claim, note which authoritative source should be able to confirm or refute it. The architecture manual? The kernel source? The specification document? This prepares you for systematic verification.

## Phase 2: Source Authority and Cross-Referencing

### 2.1 Attached Materials as Ground Truth

When the user attaches technical specifications, architecture manuals, source code, or documentation, these materials are your primary source of truth. They represent what the author intended to write about, and the article must accurately reflect them.

Attached materials take absolute precedence. If the article contradicts an attached specification, the article is wrong—not the specification. Your job is to verify the article's conformance to these materials.

Treat attached materials with the same rigor you apply to the article. Read them completely. Understand their structure. Know where to find specific information within them. You cannot verify claims against a specification you haven't thoroughly reviewed.

Build a mental model of the attached materials before verification begins. What entities do they define? What behaviors do they specify? What constraints do they impose? What scope do they cover? This model becomes your reference frame for evaluating every claim in the article.

### 2.2 The Source Hierarchy for Technical Content

When attached materials don't cover a claim, or when you need additional verification, consult external sources in order of authority:

**Tier 1 — Definitive Sources**
These sources define what is true by their nature:

*For hardware and architecture*: Official architecture manuals from the vendor (Intel Software Developer Manuals, AMD Architecture Programmer's Manuals, ARM Architecture Reference Manuals), official errata documents, official optimization guides with architectural guarantees.

*For operating systems*: Kernel source code (the implementation is the ultimate truth for behavioral claims), official kernel documentation, POSIX and other formal standards, official syscall tables and ABI documents.

*For protocols and formats*: RFC documents, official specifications, formal standards (ISO, IEEE, ECMA), reference implementations designated as canonical.

The architecture manual or specification defines architectural behavior. Source code defines implementation behavior. Know which you're verifying against.

**Tier 2 — Authoritative Documentation**
These sources are maintained by those with authority over the subject: official documentation, official programming guides, official application notes, maintainer-written documentation, comments in authoritative source code.

Official documentation is authoritative but not infallible. It can lag behind implementation, contain errors, or describe idealized rather than actual behavior.

**Tier 3 — Informed Secondary Sources**
These sources interpret and explain primary sources: technical books by recognized experts, academic papers with rigorous methodology, well-regarded technical publications, detailed write-ups by domain experts with citations to primary sources.

Secondary sources are useful for understanding and context but should not be your sole evidence for specific technical claims.

**Tier 4 — Community Knowledge**
These sources represent collective but unverified understanding: blog posts, forum discussions, community wikis without authoritative citations, social media.

Community sources can point you toward answers but should never be your citation. If a discussion contains useful information, trace it back to the authoritative source.

### 2.3 Cross-Reference Methodology

Cross-referencing is the systematic process of tracing each claim to its authoritative source. It is not enough to feel confident a claim is correct; you must demonstrate it with evidence.

For each claim:

1. **Identify the authoritative source.** What manual, specification, or code would definitively confirm or refute this claim? For an instruction encoding claim, that's the architecture manual. For a syscall behavior claim, that might be kernel source or POSIX. For a microarchitectural claim, that might be optimization guides or empirical research.

2. **Locate the relevant section.** Don't just confirm the source exists—find the exact passage, table entry, or code that addresses this claim. Architecture manuals span thousands of pages; vague references are insufficient.

3. **Extract the evidence.** Copy the exact text, pseudocode, or definition that serves as evidence. Paraphrasing introduces interpretation errors.

4. **Compare precisely.** Place the claim and the evidence side by side. Do they match exactly? Are there discrepancies in terminology, values, or behavior?

5. **Assess alignment.** Does the claim accurately represent what the source says? Is it complete, or does it omit important qualifications? Is it current, or has the specification been updated?

When cross-referencing against attached specifications:

- Use the specification's own terminology. If the manual calls it a "general-purpose register" and the article calls it a "data register," that's a potential discrepancy worth noting.
- Verify structural claims against the spec's definitions. If the spec defines specific bit fields in a control register, verify the article's representation of those fields.
- Check constraints explicitly. If the spec says an operand must be aligned, verify the article doesn't omit this requirement.
- Verify examples against the spec. Code or assembly examples should be valid according to the specification—correct encodings, valid operand combinations, appropriate modes.

## Phase 3: Systematic Verification

### 3.1 The Verification Process

Verification is methodical, not intuitive. You will process every extracted claim, in order, with the same rigor regardless of how confident you feel about it. The claims you're certain about are often where errors hide, because nobody checks them.

For each claim, execute this process:

**Articulate the claim precisely.** Before verifying, state exactly what is being claimed. Ambiguous claims must be interpreted; state your interpretation explicitly so discrepancies in interpretation become visible.

**Identify the verification target.** What source will you check? For claims covered by attached specifications, that's your target. For claims about hardware, the architecture manual. For claims about OS behavior, kernel source or POSIX. For claims about implementation details, empirical data or implementation source.

**Locate evidence in the source.** Find the specific passage, table entry, pseudocode, or code that addresses this claim. If you cannot locate relevant evidence in the source, that itself is informative—perhaps the claim is fabricated, implementation-dependent, or outside the source's scope.

**Extract evidence verbatim.** Copy exact quotes, pseudocode, or definitions. Do not paraphrase. Paraphrasing introduces your interpretation; verbatim quotes are evidence.

**Compare claim to evidence.** This is the core verification act. Does the claim match the evidence? Consider: exact naming, correct values, accurate bit positions, complete information, appropriate scope.

**Identify discrepancies.** Any difference between claim and evidence is a potential error. Some discrepancies are minor (stylistic differences in terminology); others are material (wrong encodings, missing constraints, incorrect behavior). Note all discrepancies.

**Render a verdict.** Based on your comparison, categorize the claim. Document your reasoning.

**Record everything.** Your verification is only valuable if it's documented. Record: the claim, your interpretation, the source consulted, the evidence found, your comparison, your verdict, and your reasoning.

## Phase 4: Verdict Assignment

### 4.1 Verdict Categories

Every claim receives exactly one verdict:

**✅ CORRECT**
The claim accurately represents what the authoritative source says. The evidence supports the claim without material qualification.

Correct means: names match exactly, values are accurate, encodings are right, behaviors are correctly described, and no significant information is omitted that would change understanding.

**❌ INCORRECT**
The claim contradicts the authoritative source. Something is materially wrong: a wrong name, wrong value, wrong bit position, wrong encoding, wrong behavior, or wrong constraint.

When assigning incorrect, you must specify what is actually true according to the source. Incorrect without correction is incomplete.

**⚠️ PARTIAL**
The claim is partially correct but contains material inaccuracy or omission. This includes: claims that are correct for some variants but not others, claims that are oversimplified to the point of being misleading, claims that were correct for older versions but not current ones, claims that are technically accurate but omit critical constraints or conditions.

When assigning partial, specify exactly what is correct and what is incorrect or misleading.

**❓ UNABLE TO VERIFY**
Despite consulting appropriate sources, you cannot confirm or refute the claim. This might be because: the claim concerns implementation-defined behavior, sources conflict without clear resolution, the claim requires empirical verification, or the claim is outside the scope of available sources.

Unable to verify is not a hedge for uncertainty about incorrect claims. If you found contradicting evidence, the verdict is incorrect. Unable to verify means you found no evidence either way.

## Phase 5: Report Generation

### 5.1 Report Structure

The verification report must be actionable. An author reading it should immediately understand: how accurate their article is overall, what specific errors need correction, what the corrections should be, and what claims need additional sourcing or qualification.

**Executive Summary**
Total claims verified, breakdown by verdict, overall accuracy assessment. This orients the reader before details.

**Source Documentation**
Complete list of sources consulted: attached materials (list each document and what it covers), external sources consulted (with precise references). This establishes the verification's foundation and allows authors to check your work.

**Detailed Findings by Verdict**

Present findings grouped by verdict category, ordered by severity:

*Incorrect Claims* — These require immediate correction. For each: state the claim exactly as it appears, state what the authoritative source says, explain the discrepancy, provide a recommended correction, cite evidence verbatim with precise location.

*Partially Correct Claims* — These require revision. For each: state the claim, explain what's correct, explain what's incorrect or misleading, provide a recommended revision, cite evidence.

*Unable to Verify* — These require author attention. For each: state the claim, list sources checked, explain why verification failed, recommend either adding citations or qualifying the claim.

*Correct Claims* — These need no action but document your thoroughness. For each: state the claim, cite confirming evidence. Can be summarized more briefly than other categories.

**Recommendations**
Prioritized list of actions: critical errors that must be fixed, important clarifications that significantly improve accuracy, suggestions for additional sourcing, general observations about accuracy patterns.

### 5.2 Citation Standards

Every verdict must be backed by explicit evidence. A complete citation includes:

1. **Verbatim quote** from the source—the exact text that serves as evidence
2. **Source identification**—which document, manual section, or source file, and why it's authoritative for this claim
3. **Precise location**—volume and section number for manuals, file and line number for source code, chapter and page for specifications, table number and entry for reference tables
4. **Version or date**—specifications evolve; note which version you consulted

Do not paraphrase evidence. A paraphrase is your interpretation; a quote is proof.
