# AGENTS.md

### Do
- use MUI v3. make sure your code is v3 compatible
- use emotion css={{}} prop format
- use mobx for state management with useLocalStore
- use design tokens from DynamicStyles.tsx for all styling. no hard coding
- use apex charts for charts. do not supply custom html
- default to small components
- default to small diffs

### Don't
- do not hard code colors
- do not use divs if we have a component already
- do not add new heavy dependencies without approval

### Commands
# file scoped checks preferred
npm run tsc --noEmit path/to/file.tsx
npm run prettier --write path/to/file.tsx
npm run eslint --fix path/to/file.tsx
# tests
npm run vitest run path/to/file.test.tsx
# full build when explicitly requested
npm run build:app

### Safety and permissions

Allowed without prompt:
- read files, list files
- tsc single file, prettier, eslint,
- vitest single test

Ask first: 
- package installs,
- git push
- deleting files, chmod
- running full build or end to end suites

### Project structure
- see routers/index.ts for our routes
- see @Sidebar.tsx for our sidebar
- components are in app/components
- theme tokens are in app/lib/theme/tokens.ts

### Good and bad examples
- avoid class based components like `Admin.tsx`
- use functional components with hooks like `Projects.tsx`
- forms: copy `app/components/Form.Field.tsx` and `app/components/Form.Submit.tsx`
- charts: copy `app/components/Charts/Bar.tsx` and `app/lib/chartTheme.ts`
- data layer: use `app/api/client.ts`. do not fetch in components

### API docs
- docs in ./api/docs/*.md
- list projects - GET /api/projects using app/api/client.ts
- update project name - PATCH /api/projects/:id using client.projects.update

### PR checklist
- format and type check: green
- unit tests: green. add tests for new code paths
- diff: small with a brief summary

### When stuck
- ask a clarifying question, propose a short plan, or open a draft PR with notes

### Test first mode
- write or update tests first on new features, then code to green

### Design system
- use @acme/ui per the indexed docs in ./design-system-index/*.md
- tokens come from @acme/ui/tokens