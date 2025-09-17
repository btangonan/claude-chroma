# ChromaDB Memory System - Usage Examples

## How Claude Uses Project Memory

### 🚀 Automatic Initialization (On Project Load)

When Claude opens your project, it automatically:

```javascript
// 1. Try to query existing memories
mcp__chroma__chroma_query_documents {
  "collection_name": "project_memory",
  "query_texts": ["project setup"],
  "n_results": 5
}

// 2. If collection doesn't exist, create it
mcp__chroma__chroma_create_collection {
  "collection_name": "project_memory",
  "embedding_function_name": "default"
}

// 3. Add initial project memory
mcp__chroma__chroma_add_documents {
  "collection_name": "project_memory",
  "documents": ["xml_maker: Premiere XML generator with keyword search"],
  "metadatas": [{"type": "decision", "tags": "setup,xml,video", "source": "init"}],
  "ids": ["project-init"]
}
```

### 📝 Real-World Memory Examples

#### Example 1: Architecture Decision

**Scenario**: Team decides to use a specific pattern

```javascript
// After confirming MVC pattern for API
mcp__chroma__chroma_add_documents {
  "collection_name": "project_memory",
  "documents": ["Use MVC pattern with separate controllers for each resource"],
  "metadatas": [{
    "type": "decision",
    "tags": "architecture,api,mvc,controllers",
    "source": "team-meeting-2024-01-15"
  }],
  "ids": ["api-mvc-pattern"]
}
// Claude responds: "Logged memory: api-mvc-pattern"
```

#### Example 2: Bug Fix Documentation

**Scenario**: Fixed a critical bug

```javascript
// After fixing null pointer exception
mcp__chroma__chroma_add_documents {
  "collection_name": "project_memory",
  "documents": ["Fixed auth null pointer by adding user?.id check before access"],
  "metadatas": [{
    "type": "fix",
    "tags": "auth,bug,null-pointer,validation",
    "source": "issue#456"
  }],
  "ids": ["auth-null-fix-456"]
}
// Claude responds: "Logged memory: auth-null-fix-456"
```

#### Example 3: Team Coding Preference

**Scenario**: Team agrees on coding style

```javascript
// After team discussion on formatting
mcp__chroma__chroma_add_documents {
  "collection_name": "project_memory",
  "documents": ["Use 2-space indentation, semicolons optional, trailing commas"],
  "metadatas": [{
    "type": "preference",
    "tags": "formatting,style,eslint",
    "source": "team-standards"
  }],
  "ids": ["code-style-prefs"]
}
// Claude responds: "Logged memory: code-style-prefs"
```

#### Example 4: Performance Optimization

**Scenario**: Discovered and fixed performance issue

```javascript
// After optimizing database queries
mcp__chroma__chroma_add_documents {
  "collection_name": "project_memory",
  "documents": ["Use indexed queries for user lookups, reduced load time 80%"],
  "metadatas": [{
    "type": "tip",
    "tags": "performance,database,optimization,index",
    "source": "perf-analysis"
  }],
  "ids": ["db-index-optimization"]
}
// Claude responds: "Logged memory: db-index-optimization"
```

### 🔍 Querying Memories Before Work

#### Check for Related Decisions

```javascript
// Before working on authentication
mcp__chroma__chroma_query_documents {
  "collection_name": "project_memory",
  "query_texts": ["authentication", "auth", "login"],
  "n_results": 5
}

// Returns:
{
  "documents": [
    ["Use JWT tokens with 24h expiry"],
    ["Fixed auth null pointer by adding user?.id check"],
    ["Implement 2FA using TOTP standard"]
  ],
  "metadatas": [
    {"type": "decision", "tags": "auth,jwt,security"},
    {"type": "fix", "tags": "auth,bug,null-pointer"},
    {"type": "decision", "tags": "auth,2fa,security"}
  ]
}
```

#### Filter by Type

```javascript
// Get only architecture decisions
mcp__chroma__chroma_query_documents {
  "collection_name": "project_memory",
  "query_texts": ["api"],
  "where": {"type": {"$eq": "decision"}},
  "n_results": 10
}
```

#### Search by Source

```javascript
// Find all decisions from specific PR
mcp__chroma__chroma_query_documents {
  "collection_name": "project_memory",
  "query_texts": ["*"],  // Match all
  "where": {"source": {"$contains": "PR#123"}},
  "n_results": 20
}
```

### 🔄 Updating Existing Memories

#### Update a Decision

```javascript
// Original decision
{
  "documents": ["Use REST API for all endpoints"],
  "ids": ["api-protocol"]
}

// Updated decision (same ID)
mcp__chroma__chroma_add_documents {
  "collection_name": "project_memory",
  "documents": ["Use GraphQL for queries, REST for mutations"],
  "metadatas": [{
    "type": "decision",
    "tags": "api,graphql,rest,architecture",
    "source": "architecture-review"
  }],
  "ids": ["api-protocol"]  // Same ID updates instead of duplicates
}
```

### 📊 Memory Management Operations

#### List All Memories

```javascript
// Get everything
mcp__chroma__chroma_get_documents {
  "collection_name": "project_memory"
}
```

#### Count Memories

```javascript
// Get count
mcp__chroma__chroma_get_collection_info {
  "collection_name": "project_memory"
}
// Returns: {"count": 42, "name": "project_memory", ...}
```

#### Delete Obsolete Memory

```javascript
// Remove outdated decision
mcp__chroma__chroma_delete_documents {
  "collection_name": "project_memory",
  "ids": ["old-deprecated-pattern"]
}
```

### 🎯 Advanced Queries

#### Complex Filtering

```javascript
// Find recent critical decisions
mcp__chroma__chroma_query_documents {
  "collection_name": "project_memory",
  "query_texts": ["architecture", "security", "performance"],
  "where": {
    "$and": [
      {"type": {"$eq": "decision"}},
      {"tags": {"$contains": "critical"}}
    ]
  },
  "n_results": 10
}
```

#### Semantic Search

```javascript
// Natural language query
mcp__chroma__chroma_query_documents {
  "collection_name": "project_memory",
  "query_texts": ["how do we handle user authentication?"],
  "n_results": 5
}
// ChromaDB uses embeddings to find semantically similar memories
```

### 💡 Best Practices in Action

#### 1. Log After Confirmation

```javascript
// BAD - Logging speculation
"Might use Redis for caching"  // Don't log this!

// GOOD - Logging confirmed decision
"Use Redis for session caching with 1h TTL"  // Log this after team agrees
```

#### 2. Use Descriptive IDs

```javascript
// BAD - Random or generic IDs
"ids": ["memory-1", "fix-2", "abc123"]

// GOOD - Meaningful, stable IDs
"ids": ["auth-jwt-implementation", "bug-fix-null-user-456", "api-rate-limiting"]
```

#### 3. Rich Tagging

```javascript
// BAD - Minimal tags
"tags": "bug"

// GOOD - Comprehensive tags
"tags": "bug,auth,security,high-priority,user-reported,session-management"
```

#### 4. Clear Source Attribution

```javascript
// BAD - Vague source
"source": "meeting"

// GOOD - Specific source
"source": "architecture-review-2024-01-15-with-senior-team"
```

### 🔮 Automatic Behavior

Claude automatically:

1. **Queries before proposing**: Checks existing decisions before suggesting solutions
2. **Logs after implementation**: Records decisions/fixes after they're confirmed working
3. **Updates instead of duplicates**: Uses same ID to update existing memories
4. **Maintains context**: Refers to past decisions when relevant

### 📚 Complete Workflow Example

```javascript
// Session 1: Initial decision
// 1. Query for existing patterns
query: "database patterns"
// No results

// 2. Team decides on pattern
add: "Use repository pattern with TypeORM for data access"
id: "db-repository-pattern"

// Session 2: Building on decision
// 1. Query before starting
query: "database repository"
// Returns: "Use repository pattern with TypeORM"

// 2. Implement following the pattern
// ... code implementation ...

// 3. Discover optimization
add: "Cache repository results using decorators for 5min TTL"
id: "db-repository-caching"

// Session 3: Someone asks about database
// Claude automatically queries and finds both memories
// Suggests solutions based on established patterns
```

---

This is how ChromaDB memories work in practice - automatically preserving project knowledge across Claude sessions!