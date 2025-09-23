#!/usr/bin/env uvx chromadb-cli@latest
"""
Chroma statistics helper for ChromaDB projects.
Reports memory count and breakdown by type.
Zero-dependency execution via uvx.
"""
import os
import sys
import json

try:
    import chromadb
    from chromadb.config import Settings
except ImportError:
    print(json.dumps({
        "collection": os.environ.get("CHROMA_COLLECTION", "project_memory"),
        "total": 0,
        "by_type": {},
        "status": "error",
        "error": "ChromaDB not available. Install with: pip install chromadb"
    }))
    sys.exit(1)

def main():
    # Get configuration from environment or defaults
    COL = os.environ.get("CHROMA_COLLECTION", "project_memory")
    DATA = os.environ.get("CHROMA_DATA_DIR", os.path.join(os.getcwd(), ".chroma"))

    try:
        # Connect to Chroma
        client = chromadb.PersistentClient(path=DATA, settings=Settings(allow_reset=False))

        # Get or create collection
        try:
            col = client.get_collection(name=COL)
        except:
            # Collection doesn't exist yet
            print(json.dumps({
                "collection": COL,
                "total": 0,
                "by_type": {},
                "status": "new_collection"
            }))
            return

        # Pull metadatas to count by type
        # Limit to 100k to avoid memory issues on large collections
        result = col.get(include=["metadatas"], limit=100000)

        # Count by type
        types = {}
        for meta in (result.get("metadatas") or []):
            t = (meta or {}).get("type", "unknown")
            types[t] = types.get(t, 0) + 1

        total = sum(types.values())

        # Output JSON result
        print(json.dumps({
            "collection": COL,
            "total": total,
            "by_type": types,
            "status": "success"
        }))

    except Exception as e:
        # Return error info
        print(json.dumps({
            "collection": COL,
            "total": 0,
            "by_type": {},
            "status": "error",
            "error": str(e)
        }))
        sys.exit(1)

if __name__ == "__main__":
    main()