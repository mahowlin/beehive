# /deep-plan - Structured Plan Creation

Use before creating a plan that requires exploration or has multiple possible approaches.

Perform these steps:

1. **Enter plan mode** — Recommend entering plan mode (Shift+Tab) for focused exploration

2. **Explore** — Read relevant code, understand patterns, identify constraints
   - What files are involved?
   - What patterns does the codebase use?
   - What are the boundaries and constraints?
   - What existing code can be reused?

3. **Reason** — Consider alternatives, evaluate trade-offs, document WHY
   - What are 2-3 approaches?
   - What are the pros/cons of each?
   - Why is the chosen approach best for this context?

4. **Draft** — Write the plan using `plans/TEMPLATE.md` with all reasoning sections filled:
   - Objective (one sentence)
   - Technical Context (key files, patterns, constraints)
   - Tasks (with rationale for each)
   - Risks / Open Questions
   - Done Criteria (explicit, verifiable)

5. **Validate** — Self-check the plan:
   - Could a Bee execute this without asking clarifying questions?
   - Are tasks logically sequenced?
   - Is each Done Criterion independently verifiable?
   - Are there implicit dependencies that should be explicit?

6. **Write** — Exit plan mode and:
   - Write the final plan file to `plans/`
   - Add a work item to `work.jsonl`:
     ```json
     {"id":"P-NNN","type":"plan","title":"Plan name","file":"plans/plan-name.md","status":"ready","priority":"HIGH","points":2,"assigned":"","parent":"","deliverable":"","created":"2026-01-20","updated":"2026-01-20"}
     ```

**When to use /deep-plan vs. quick plan creation:**
- **/deep-plan**: Multi-file changes, architectural decisions, unfamiliar code areas, 3+ point plans
- **Quick plan**: Single-file changes, well-understood patterns, 1-point plans
