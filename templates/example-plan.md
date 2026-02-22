# Add User Authentication

> **Rules (read before every task):**
> - Edit ONLY: Task checkboxes, Completion Summary, Session State, and sections during /buzz or /bedtime
> - Out-of-scope work → /report
> - Before finishing → /buzz
> - If you accidentally edited TRACKER.md → revert and tell Queen

**Priority:** HIGH
**Points:** 2
**Blocked By:** -

## Objective

Users can log in with email/password and stay authenticated across sessions.

## Why This Approach

Considered OAuth (too complex for MVP), magic links (requires email service), and basic email/password. Chose email/password with bcrypt + JWT because it uses only existing dependencies, the User model already has an email field, and we can add OAuth later without breaking changes.

## Technical Context

- **Key files:** `src/models/user.ts` (User model), `src/routes/index.ts` (route setup), `src/middleware/` (existing middleware pattern)
- **Existing patterns:** Routes use Express router with middleware chain; models use TypeORM decorators; UI uses React components in `src/components/`
- **Constraints:** Must preserve existing User model fields (email, name, createdAt); must not require database migration beyond adding password column

## Implementation Strategy

Start with the data layer (password hashing on the User model), then build the API endpoints for login/register. Once the backend works, add JWT session middleware that protects routes. Finally, build the UI components and wire them to the API. This order lets us test each layer independently.

## Tasks

- [ ] Add password hashing with bcrypt — secure credential storage before building endpoints
- [ ] Create login/register API endpoints — backend auth flow needed before UI
- [ ] Add session middleware with JWT — enables protected routes
- [ ] Create login/register UI components — user-facing auth interface
- [ ] Add protected route wrapper — enforces auth on private pages

## Risks / Open Questions

- JWT secret storage: use env var or config file? (Check project conventions)
- Token expiration policy: 24h default, but confirm with user
- Rate limiting on login endpoint: defer to separate plan or include here?

## Done Criteria

- [ ] Can register new user via UI
- [ ] Can log in with registered credentials
- [ ] Session persists across browser refresh
- [ ] Protected routes redirect to login when unauthenticated

---

## Session State
<!-- Updated by /buzz and /bedtime — tracks live progress -->

**Last Updated:** -
**Current Task:** -
**Next Step:** -
**Context Notes:** -

---

## Completion Summary

**Achieved:** [1-2 sentences of what was done]
**Resume Notes:** [If incomplete - where to pick up. Leave blank if fully complete.]
