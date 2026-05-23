# Prompt: Frontend QA

> Use when reviewing or testing a frontend application.

---

## Task

Perform a frontend QA review of the project at: `[PROJECT_PATH]`

**Frontend framework:** `[React / Vue / Next.js / Vanilla / etc.]`
**Key flows to test:** `[e.g., login, checkout, dashboard load]`

## QA Checklist

### Functionality
- [ ] Core user flows work end-to-end
- [ ] Forms validate inputs before submission
- [ ] Error states are handled gracefully (no blank pages or "undefined" text)
- [ ] Loading states are shown for async operations
- [ ] Navigation works (no broken links, correct redirects)

### Accessibility
- [ ] Images have alt text
- [ ] Form inputs have labels
- [ ] Page has a meaningful `<title>`
- [ ] Keyboard navigation works for key flows
- [ ] Color contrast is sufficient

### Performance
- [ ] Page loads in under 3 seconds on a simulated 3G connection
- [ ] No obviously large unbundled scripts
- [ ] Images are appropriately sized

### Security
- [ ] No sensitive data (tokens, user IDs) exposed in URL query params
- [ ] API calls use HTTPS
- [ ] No credentials in JavaScript bundle or network requests

### Mobile
- [ ] Layout is usable on a 375px wide screen
- [ ] Touch targets are at least 44x44px
- [ ] No horizontal scrolling on mobile

## Output Format

1. **Passed** items
2. **Failed** items with reproduction steps
3. **Severity** for each failure (Critical / High / Medium / Low)
4. **Screenshots or logs** if available
