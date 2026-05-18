---
name: First Principles Thinking
description: This skill should be used when the user asks to "analyze from first principles", "第一性原理", "从根本分析", "从零开始思考", "think from scratch", "question this design", "这个设计合理吗", "is this the right approach", "为什么要这样做", "why are we doing it this way", "有没有更好的方案", "is there a better solution", "challenge assumptions", "挑战假设", or needs to evaluate architectural decisions, design choices, or problem-solving approaches without relying on analogies or conventions.
version: 0.2.0
---

# First Principles Thinking

Break problem → fundamental truths → reason up. No analogy trap.

## When to Use This Skill

- Check if architecture/design truly optimal
- Question "best practices" that may not fit context
- Break through when conventional solutions inadequate
- Make foundational decisions w/ long-term impact
- Challenge inherited assumptions in legacy
- Design new systems without cargo-culting

## Core Process

### Phase 1: Identify the Problem's Essence

Strip implementation → find core problem:

1. **State the problem clearly** - What exactly needs solving?
2. **Separate symptoms from causes** - Real problem or manifestation?
3. **Define success criteria** - What would perfect solution achieve?

**Key Questions:**

- What fundamental job to be done?
- If system didn't exist, what users actually need?
- What outcome matters, independent of how we get there?

### Phase 2: Challenge All Assumptions

Identify & question every assumption:

1. **List explicit assumptions** - What taking as given?
2. **Surface implicit assumptions** - What conventions following without questioning?
3. **Test each assumption** - Actually constraint, or just how always done?

**Assumption Categories:**

| Category   | Question to Ask                            |
| ---------- | ------------------------------------------ |
| Technical  | "Must we use this technology/pattern?"     |
| Business   | "Is this requirement actually fixed?"      |
| Resource   | "Are these constraints real or perceived?" |
| Historical | "Why was this decision made originally?"   |

**Red Flags (likely false assumptions):**

- "We've always done it this way"
- "Industry standard says..."
- "Everyone uses X for this"
- "That's too simple to work"

### Phase 3: Establish Ground Truths

Identify irreducible facts:

1. **Physics/Math constraints** - What cannot be violated?
2. **Business invariants** - What must remain true for business?
3. **User needs** - What user fundamentally requires?

**Ground Truth Test:**

- Can this be further decomposed?
- Provably true, not just commonly believed?
- Would violating this definitely cause failure?

### Phase 4: Reason Upward

Build solutions from ground truths:

1. **Start minimal** - Simplest thing that satisfies ground truths?
2. **Add only what's necessary** - Each addition must justify itself
3. **Challenge each layer** - Does this layer earn its complexity?

**Building Blocks Approach:**

```
Ground Truth → Minimal Solution → Justified Additions → Final Design
     ↑              ↑                    ↑
  (proven)     (sufficient)        (each defended)
```

### Phase 5: Validate the Reasoning

Ensure solution sound:

1. **Trace back to ground truths** - Can every design decision be traced to fundamental need?
2. **Identify weak links** - Where does reasoning rely on assumptions?
3. **Stress test** - What would break this solution?

## Output Format

When applying first principles thinking, structure analysis as:

```markdown
## First Principles Analysis: [Topic]

### 1. Problem Essence

**Core problem:** [One sentence]
**Success criteria:** [Measurable outcomes]

### 2. Assumptions Challenged

| Assumption   | Challenge         | Verdict               |
| ------------ | ----------------- | --------------------- |
| [Assumption] | [Why question it] | [Keep/Discard/Modify] |

### 3. Ground Truths

- [Irreducible fact 1]
- [Irreducible fact 2]
- [Irreducible fact 3]

### 4. Reasoning Chain

Ground Truth → [Step 1] → [Step 2] → Solution

### 5. Conclusion

**Recommended approach:** [Description]
**Key insight:** [What the first principles analysis revealed]
**Trade-offs acknowledged:** [What we're accepting]
```

## Common Patterns

### Pattern: The Complexity Trap

**Symptom:** Solution more complex than problem warrants

**First Principles Check:**

1. Remove one component - system still solve core problem?
2. If yes, that component wasn't essential
3. Repeat until removal breaks core functionality

### Pattern: The Analogy Trap

**Symptom:** "Company X does it this way, so we should too"

**First Principles Check:**

1. What problem was Company X actually solving?
2. Our problem identical in all relevant dimensions?
3. What constraints did they have that we don't (and vice versa)?

### Pattern: The Legacy Trap

**Symptom:** Maintaining compatibility w/ decisions that no longer serve us

**First Principles Check:**

1. What was original reason for this decision?
2. Do those conditions still exist?
3. True cost of change vs. cost of maintaining?

## Integration with Other Thinking Tools

First principles thinking works well w/ complementary approaches:

| Tool                   | When to Combine                  | How                                   |
| ---------------------- | -------------------------------- | ------------------------------------- |
| **Trade-off Analysis** | After identifying ground truths  | Evaluate options against fundamentals |
| **5-Whys**             | When assumptions surface         | Dig deeper to find root causes        |
| **Pre-mortem**         | Before finalizing solution       | Stress-test reasoning chain           |
| **Hypothesis Testing** | When ground truths are uncertain | Validate assumptions empirically      |

## Boundaries

**Will:**

- Challenge assumptions systematically
- Identify ground truths from first principles
- Build reasoning chains from fundamentals
- Reveal when conventional wisdom doesn't apply

**Will Not:**

- Dismiss all existing solutions as wrong
- Spend unlimited time on every decision (reserve for important choices)
- Ignore practical constraints in favor of theoretical purity
- Guarantee the "best" solution (reveals better reasoning, not perfect answers)

## Quick Reference

**The First Principles Checklist:**

- [ ] Problem stated in terms of outcomes, not solutions
- [ ] All assumptions explicitly listed
- [ ] Each assumption challenged and justified
- [ ] Ground truths identified and verified
- [ ] Solution built up from ground truths only
- [ ] Every design decision traceable to a ground truth
- [ ] Reasoning chain documented

## Additional Resources

### Reference Files

- **`references/elon-musk-examples.md`** - Real-world examples from SpaceX and Tesla
- **`references/software-examples.md`** - Software engineering applications

### Example Files

- **`examples/architecture-review.md`** - First principles analysis of a microservices decision
