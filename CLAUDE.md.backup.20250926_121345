# CLAUDE.md — Project Contract for ChromaDB

**Purpose**: Manage project memory using ChromaDB for persistent knowledge across sessions.

## 🧠 Project Memory (Chroma)

Use server `chroma`. Collection `project_memory`.

Log after any confirmed fix, decision, gotcha, or preference.

**Schema:**
- **documents**: 1–2 sentences. Under 300 chars.
- **metadatas**: `{ "type":"decision|fix|tip|preference", "tags":"comma,separated", "source":"file|PR|spec|issue" }`
- **ids**: stable string if updating the same fact.

Always reply after writes: **Logged memory: <id>**.

Before proposing work, query Chroma for prior facts.

### Chroma Calls
```javascript
// Create once:
mcp__chroma__chroma_create_collection { "collection_name": "project_memory" }

// Add:
mcp__chroma__chroma_add_documents {
  "collection_name": "project_memory",
  "documents": ["<text>"],
  "metadatas": [{"type":"<type>","tags":"a,b,c","source":"<src>"}],
  "ids": ["<stable-id>"]
}

// Query:
mcp__chroma__chroma_query_documents {
  "collection_name": "project_memory",
  "query_texts": ["<query>"],
  "n_results": 5
}
```

### Memory Examples
```javascript
documents: ["Fixed claude-chroma by using .mcp.json for server loading"]
metadatas: [{ "type":"fix","tags":"mcp,config,chroma","source":"claude-chroma.sh" }]
ids: ["fix-mcp-loading"]

documents: ["Use both .mcp.json (server) and CLAUDE.md (instructions)"]
metadatas: [{ "type":"decision","tags":"config,architecture","source":"troubleshooting" }]
ids: ["dual-config-approach"]
```

## 📋 Session Lifecycle

- **Start**: Query Chroma for context relevant to the task
- **Work**: Log decisions and fixes as they happen
- **Checkpoint**: Every major milestone, log a memory
- **End**: Summarize key memories written

## 🚀 Activation

Read this file at chat start.

Acknowledge: **Contract loaded. Using Chroma project_memory.**

If Chroma MCP is missing, state "Chroma MCP server not available" and continue.