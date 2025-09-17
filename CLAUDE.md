CLAUDE.md — Starter Project Contract
Purpose

Use this file as the working agreement. Keep memory sharp. Keep outputs concrete. Reduce rework.

Tool policy
Project memory (Chroma)

Use the chroma server. Collection name: project_memory.

When a fix, decision, gotcha, or preference is confirmed, log a memory.

Schema:

documents: 1–2 sentences, under 300 chars.

metadatas: { "type": "decision|fix|tip|preference", "tags": "comma,separated", "source": "file|PR|spec|issue" }

ids: stable string if updating the same fact.

Always reply after writes: Logged memory: <id>.

Before proposing work, query Chroma for prior facts.

Chroma calls

Create once per project:

mcp__chroma__chroma_create_collection { "name": "project_memory" }

Add:

mcp__chroma__chroma_add_documents { "collection": "project_memory", "documents": ["<text>"], "metadatas": [{"type":"<type>","tags":"a,b,c","source":"<src>"}], "ids": ["<stable-id>"] }

Query:

mcp__chroma__chroma_query_documents { "collection": "project_memory", "query_texts": ["<query>"], "n_results": 5 }

Deterministic reasoning

Default: concise, action oriented.

If I say “reason stepwise,” enable the sequential-thinking tool for one turn, then disable.

If a task has 3 or more dependent steps, propose stepwise once, then return to normal.

Browser automation and checks

Use playwright to load pages, scrape DOM, run quick tests, and export screenshots or PDFs.

Save artifacts to ./backups/ with timestamped filenames.

Summarize findings and list file paths.

GitHub MCP

Allowed: read files, list and inspect issues and PRs, draft comments, draft PR descriptions.

Not allowed without explicit approval: pushing commits, merging, closing PRs.

Always show the diff, file paths, or PR numbers before proposing changes.

Spec and planning (lite)

For new features, run a three phase loop:

/specify user stories, functional requirements, acceptance criteria.

/plan stack, architecture, constraints, performance and testing goals.

/tasks granular, test-first steps.

Log key spec and plan decisions to Chroma as type:"decision" with tags.

Quality gates

Each requirement must be unambiguous, testable, and bounded.

Prefer tests and diffs over prose.

Mark uncertainty with [VERIFY] and propose checks to resolve it.

Include simple performance budgets where relevant. Example: search under 100 ms at 10k rows.

Session hygiene

Do not compact long chats.

If context gets heavy, propose pruning to the last 20 turns and continue.

For large exports or diffs, write files to ./backups/ and return paths.

Retrieval checklist before coding

Query Chroma for related memories.

Check repo files that match the task.

List open PRs or issues that touch the same area.

Only then propose changes.

Memory taxonomy

type: decision, fix, tip, preference.

tags: domain keywords. Example: video,encode,preview.

id rule: stable handle per fact. Example: encode-preview-policy.

Memory examples

documents: Use NVENC for H.264 previews; fallback x264 if GPU is busy.
metadatas: { "type":"tip","tags":"video,encode,preview","source":"PR#142" }
ids: encode-preview-policy

documents: Adopt Conventional Commits and run tests on pre-push.
metadatas: { "type":"decision","tags":"repo,workflow,testing","source":"spec" }
ids: repo-commit-policy

Output policy

For code, return a unified diff or patchable file set.

For scripts, provide exact commands and paths.

Keep long outputs in ./backups/. Use readable names. Echo paths in the reply.

Safety

Do not include secrets in .chroma or transcripts.

Note licenses and third party terms when adding dependencies.

Respect rate limits. Propose batching if needed.

Modes

Small change mode

Skip full spec. Still log key decisions. Still show diffs.

Feature mode

Use the three phase loop. Enforce quality gates.

Activation

Read this file at chat start.

Acknowledge: Contract loaded. Using Chroma project_memory.

If tools are missing, state the missing server name and wait for direction.

You said:
do this for our generic claude.md Suggestions for Enhancement

  1. Add Missing MCP Servers

  ### Additional MCP Servers
  - **context7**: Library docs (/docs react hooks)
  - **magic**: UI components (/ui button)
  - **sequential-thinking**: Complex reasoning (auto-enabled for 3+ steps)

  2. Include Tool Selection Matrix

  ### Tool Selection
  Task → Tool:
  - Multi-file edits → MultiEdit
  - Pattern search → Grep (not bash grep)
  - UI generation → Magic MCP
  - Complex analysis → Sequential-thinking

  3. Add Session Management

  ### Session Lifecycle
  1. Start: Query Chroma for context
  2. Work: Log decisions as you go
  3. Checkpoint: Every 30min or major milestone
  4. End: Summary of changes + memories logged
ChatGPT said:
Thought for 19s

Here’s a tight generic CLAUDE.md with your enhancements baked in. Drop it in any repo.

CLAUDE.md — Starter Project Contract
Purpose

Follow this in every chat for this repo. Keep memory sharp. Keep outputs concrete. Cut rework.

Tool policy
Project memory (Chroma)

Use server chroma. Collection project_memory.

Log after any confirmed fix, decision, gotcha, or preference.

Schema:

documents: 1–2 sentences. Under 300 chars.

metadatas: { "type":"decision|fix|tip|preference", "tags":"comma,separated", "source":"file|PR|spec|issue" }

ids: stable string if updating the same fact.

Always reply after writes: Logged memory: <id>.

Before proposing work, query Chroma for prior facts.

Chroma calls

Create once:

mcp__chroma__chroma_create_collection { "name": "project_memory" }

Add:

mcp__chroma__chroma_add_documents { "collection":"project_memory","documents":["<text>"],"metadatas":[{"type":"<type>","tags":"a,b,c","source":"<src>"}],"ids":["<stable-id>"] }

Query:

mcp__chroma__chroma_query_documents { "collection":"project_memory","query_texts":["<query>"],"n_results":5 }

Deterministic reasoning

Default: concise, action oriented.

Auto-propose sequential-thinking when a task has 3+ dependent steps or multiple tradeoffs. Enable for one turn, then disable.

If I say “reason stepwise”, enable for one turn, then disable.

Browser automation

Use playwright to load pages, scrape DOM, run checks, and export screenshots or PDFs.

Save artifacts to ./backups/ with timestamped filenames.

Summarize results and list file paths.

GitHub

Use github to fetch files, list and inspect issues and PRs, and draft PR comments.

Never push or merge without explicit approval.

Always show diffs, file paths, or PR numbers before proposing changes.

Additional MCP servers

context7: library docs search. Example: /docs react hooks.

magic: UI components and small React blocks. Example: /ui button.

sequential-thinking: complex planning mode as above.

Tool selection matrix
Task	Tool
Multi-file edits	MultiEdit (if available). Otherwise propose a unified diff per file.
Pattern search in repo	Grep MCP (not shell grep). Return matches with file paths and line numbers.
UI snippet or component	Magic MCP. Return a self-contained file.
Complex analysis or planning	Sequential-thinking for one turn.
Docs or library behavior	context7 first. Quote relevant lines, then summarize.
Web page check or scrape	Playwright with artifacts saved to ./backups/.

If a listed tool is missing, state the exact server or tool name that is unavailable and ask to enable it.

Spec and planning (lite)

For new features, run three phases:

/specify user stories, functional requirements, acceptance tests.

/plan stack, architecture, constraints, performance and testing goals.

/tasks granular, test-first steps.

Log key spec and plan decisions to Chroma as type:"decision" with tags.

Quality gates

Every requirement is unambiguous, testable, and bounded.

Prefer tests and unified diffs over prose.

Mark uncertainty with [VERIFY] and propose checks.

Include simple performance budgets where relevant. Example: search under 100 ms at 10k rows.

Session lifecycle

Start: query Chroma for context relevant to the task. List any matches you will rely on.

Work: log decisions and gotchas as they happen. Keep each memory under 300 chars.

Checkpoint: every 30 minutes or at a major milestone, summarize progress, open risks, and memories logged.

End: summarize changes, link artifacts in ./backups/, and list all memories written.

Session hygiene

Do not compact long chats.

If context gets heavy, propose pruning to the last 20 turns and continue.

For long outputs, write files to ./backups/ and return paths.

Retrieval checklist before coding

Query Chroma for related memories.

Check repo files that match the task.

List open PRs or issues that touch the same area.

Only then propose changes.

Memory taxonomy

type: decision, fix, tip, preference.

tags: short domain keywords. Example: video,encode,preview.

id rule: stable handle per fact. Example: encode-preview-policy.

Memory examples

documents: Use NVENC for H.264 previews; fallback x264 if GPU is busy.
metadatas: { "type":"tip","tags":"video,encode,preview","source":"PR#142" }
ids: encode-preview-policy

documents: Adopt Conventional Commits and run tests on pre-push.
metadatas: { "type":"decision","tags":"repo,workflow,testing","source":"spec" }
ids: repo-commit-policy

Output policy

For code, return a unified diff or a patchable file set.

For scripts, include exact commands and paths.

Save long outputs in ./backups/. Use readable names. Echo paths in the reply.

Safety

No secrets in .chroma or transcripts.

Note licenses and third party terms when adding dependencies.

Respect rate limits. Propose batching if needed.

Modes

Small change: skip full spec. Still log key decisions. Still show diffs.

Feature: run the three phases. Enforce quality gates.

Activation

Read this file at chat start.

Acknowledge: Contract loaded. Using Chroma project_memory.

If tools are missing, name them and stop before continuing.