# /deep-plan - Structured Plan Creation

Use before creating a plan that requires exploration or has multiple possible approaches.

This is a Beehive-native planning workflow. Stay in normal mode. Do **not** enter Claude Code plan mode, use Shift+Tab, or invoke `/plan`.

Perform these steps:

1. **Explore** — Read relevant code, understand patterns, identify constraints
   - What files are involved?
   - What patterns does the codebase use?
   - What are the boundaries and constraints?
   - What existing code can be reused?

2. **Reason** — Consider alternatives, evaluate trade-offs, document WHY
   - What are 2-3 approaches?
   - What are the pros/cons of each?
   - Why is the chosen approach best for this context?

3. **Draft** — Write `plans/<slug>.md` from `templates/plan.md` with all sections filled:
   - Objective (one sentence)
   - Technical Context (key files, patterns, constraints)
   - Tasks (with rationale for each)
   - Done Criteria (explicit, verifiable)

4. **Validate** — Self-check the plan:
   - Could a Bee execute this without asking clarifying questions?
   - Are tasks logically sequenced?
   - Is each Done Criterion independently verifiable?
   - Are there implicit dependencies that should be explicit?

5. **Link the plan to beads** — After the file is drafted:
   - Create the epic in beads with the description exactly:
     ```bash
     bd create "Plan name" --type epic -p 1 --description "Plan file: plans/<slug>.md"
     ```
   - Capture the returned epic id
   - Immediately write that id into `PLAN-META.id` in `plans/<slug>.md`

6. **Create child work** — Only after the plan file and epic are linked:
   - Create child tasks:
     ```bash
     bd create "Task 1 description" --parent <epic-id> --description "Done when: ..."
     bd create "Task 2 description" --parent <epic-id> --description "Done when: ..."
     ```
   - Set dependencies between tasks if needed:
     ```bash
     bd dep add <task-2-id> <task-1-id>   # task-2 depends on task-1
     ```

Keep beads descriptions lightweight. The plan file holds the full spec; beads should point to it.

**When to use /deep-plan vs. quick plan creation:**
- **/deep-plan**: Multi-file changes, architectural decisions, unfamiliar code areas, 3+ point plans
- **Quick plan**: Single-file changes, well-understood patterns, 1-point plans
