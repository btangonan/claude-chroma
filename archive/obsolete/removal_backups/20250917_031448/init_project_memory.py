#!/usr/bin/env python3
"""
ChromaDB Project Memory Initialization Script
Initializes persistent memory for Claude Desktop projects
Works with stdio MCP mode (uses .chroma directory)
"""

import json
import os
import sys
import argparse
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

try:
    import chromadb
    from chromadb.config import Settings
    CHROMADB_AVAILABLE = True
except ImportError:
    CHROMADB_AVAILABLE = False
    print("Warning: chromadb not installed. Install with: pip install chromadb")

# Security validation functions
def validate_path_safe(file_path: str, base_dir: Path) -> bool:
    """Validate that file_path is safe and within base_dir"""
    try:
        # Resolve paths to prevent directory traversal
        abs_base = base_dir.resolve()
        abs_path = (base_dir / file_path).resolve()

        # Check if path is within base directory
        if not str(abs_path).startswith(str(abs_base)):
            print(f"Error: Path '{file_path}' is outside project directory")
            return False

        # Check for suspicious path components
        suspicious = ['..', '~', '$', '`']
        if any(sus in file_path for sus in suspicious):
            print(f"Error: Path '{file_path}' contains suspicious characters")
            return False

        return True
    except (ValueError, OSError) as e:
        print(f"Error: Invalid path '{file_path}': {e}")
        return False

def safe_read_file(file_path: Path, max_size: int = 10 * 1024 * 1024) -> str:
    """Safely read file with size limits"""
    try:
        # Check file size before reading
        if file_path.stat().st_size > max_size:
            raise ValueError(f"File too large: {file_path.stat().st_size} bytes (max: {max_size})")

        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"Error reading file '{file_path}': {e}")
        raise

# Configuration
COLLECTION_NAME = "project_memory"
DATA_DIR = ".chroma"  # Matches stdio MCP configuration

# ANSI color codes
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'  # No Color


class ProjectMemoryInitializer:
    """Initialize and manage project memory in ChromaDB"""

    def __init__(self, project_path: str = "."):
        self.project_path = Path(project_path).resolve()
        self.project_name = self.project_path.name
        self.client = None
        self.collection = None

    def connect(self) -> bool:
        """Connect to ChromaDB using persistent client (stdio MCP mode)"""
        if not CHROMADB_AVAILABLE:
            print(f"{RED}❌ ChromaDB library not available{NC}")
            return False

        try:
            # Use persistent client for stdio MCP mode
            db_path = self.project_path / DATA_DIR
            self.client = chromadb.PersistentClient(
                path=str(db_path),
                settings=Settings(anonymized_telemetry=False)
            )
            print(f"{GREEN}✅ Connected to ChromaDB at {db_path}{NC}")
            return True
        except Exception as e:
            print(f"{RED}❌ Could not connect to ChromaDB: {e}{NC}")
            return False

    def create_or_get_collection(self) -> bool:
        """Create or get the project memory collection"""
        if not self.client:
            return False

        try:
            # Check if collection exists
            collections = self.client.list_collections()
            collection_names = [c.name for c in collections]

            if COLLECTION_NAME in collection_names:
                self.collection = self.client.get_collection(COLLECTION_NAME)
                count = self.collection.count()
                print(f"{GREEN}✅ Found existing collection with {count} memories{NC}")
            else:
                # Create new collection
                self.collection = self.client.create_collection(
                    name=COLLECTION_NAME,
                    metadata={"project": self.project_name}
                )
                print(f"{GREEN}✅ Created new collection: {COLLECTION_NAME}{NC}")

                # Add initial memory
                self.add_initial_memory()

            return True
        except Exception as e:
            print(f"{RED}❌ Error with collection: {e}{NC}")
            return False

    def add_initial_memory(self):
        """Add the initial project memory entry"""
        try:
            # Detect project type
            project_type = self.detect_project_type()

            initial_doc = f"{self.project_name}: {project_type} project initialized with ChromaDB memory"

            self.collection.add(
                documents=[initial_doc],
                metadatas=[{
                    "type": "decision",
                    "tags": "setup,init,chromadb",
                    "source": "init",
                    "timestamp": datetime.now().isoformat()
                }],
                ids=["project-init"]
            )
            print(f"{GREEN}✅ Added initial project memory{NC}")
        except Exception as e:
            print(f"{YELLOW}⚠️  Could not add initial memory: {e}{NC}")

    def detect_project_type(self) -> str:
        """Detect the type of project based on files present"""
        checks = [
            ("package.json", "Node.js"),
            ("requirements.txt", "Python"),
            ("Cargo.toml", "Rust"),
            ("go.mod", "Go"),
            ("pom.xml", "Java Maven"),
            ("build.gradle", "Java Gradle"),
            ("Gemfile", "Ruby"),
            ("composer.json", "PHP"),
            (".csproj", "C#"),
            ("CMakeLists.txt", "C/C++"),
        ]

        for filename, project_type in checks:
            if any(self.project_path.glob(f"**/{filename}")):
                return project_type

        return "General"

    def add_memory(self, document: str, memory_type: str, tags: str, source: str, memory_id: str):
        """Add a memory to the collection"""
        if not self.collection:
            return False

        try:
            self.collection.add(
                documents=[document],
                metadatas=[{
                    "type": memory_type,
                    "tags": tags,
                    "source": source,
                    "timestamp": datetime.now().isoformat()
                }],
                ids=[memory_id]
            )
            print(f"{GREEN}✅ Logged memory: {memory_id}{NC}")
            return True
        except Exception as e:
            print(f"{RED}❌ Error adding memory: {e}{NC}")
            return False

    def import_existing_decisions(self, decisions_file: Optional[str] = None):
        """Import existing project decisions from a file"""
        if decisions_file and validate_path_safe(decisions_file, self.project_path) and Path(decisions_file).exists():
            import_path = Path(decisions_file)
        else:
            # Look for common documentation files
            possible_files = [
                "DECISIONS.md",
                "ADR/README.md",  # Architecture Decision Records
                "docs/decisions.md",
                "CHANGELOG.md"
            ]

            import_path = None
            for filename in possible_files:
                path = self.project_path / filename
                if path.exists():
                    import_path = path
                    break

            if not import_path:
                print(f"{YELLOW}No existing decisions file found{NC}")
                return

        print(f"{BLUE}Importing decisions from {import_path.name}...{NC}")

        # Parse and import decisions (simplified example)
        try:
            content = safe_read_file(import_path)

            # Simple extraction of decisions (customize based on format)
            lines = content.split('\n')
            decision_count = 0

            for i, line in enumerate(lines):
                if line.startswith('## ') or line.startswith('### '):
                    # Found a decision header
                    title = line.strip('#').strip()
                    if len(title) < 300:  # ChromaDB document limit
                        memory_id = f"import-{i}-{title[:30].replace(' ', '-').lower()}"
                        self.add_memory(
                            document=title,
                            memory_type="decision",
                            tags="imported,historical",
                            source=import_path.name,
                            memory_id=memory_id
                        )
                        decision_count += 1

            print(f"{GREEN}✅ Imported {decision_count} historical decisions{NC}")
        except Exception as e:
            print(f"{YELLOW}⚠️  Error importing decisions: {e}{NC}")

    def query_memories(self, query: str, n_results: int = 5):
        """Query existing memories"""
        if not self.collection:
            return []

        try:
            results = self.collection.query(
                query_texts=[query],
                n_results=n_results
            )
            return results
        except Exception as e:
            print(f"{RED}❌ Error querying memories: {e}{NC}")
            return []

    def list_all_memories(self):
        """List all memories in the collection"""
        if not self.collection:
            return

        try:
            # Get all documents
            results = self.collection.get()

            if not results['ids']:
                print(f"{YELLOW}No memories found{NC}")
                return

            print(f"\n{BLUE}=== Project Memories ({len(results['ids'])} total) ==={NC}")

            for i, (doc_id, doc, metadata) in enumerate(zip(
                results['ids'],
                results['documents'],
                results['metadatas']
            )):
                print(f"\n{GREEN}[{i+1}] ID: {doc_id}{NC}")
                print(f"  📝 {doc}")
                print(f"  🏷️  Type: {metadata.get('type', 'unknown')}")
                print(f"  🔖 Tags: {metadata.get('tags', '')}")
                print(f"  📁 Source: {metadata.get('source', '')}")
                if 'timestamp' in metadata:
                    print(f"  🕐 Time: {metadata['timestamp']}")

        except Exception as e:
            print(f"{RED}❌ Error listing memories: {e}{NC}")

    def export_memories(self, output_file: str = "memories_export.json"):
        """Export all memories to a JSON file"""
        # Validate output path for security
        if not validate_path_safe(output_file, self.project_path):
            print(f"{RED}❌ Invalid output file path: {output_file}{NC}")
            return

        if not self.collection:
            return

        try:
            results = self.collection.get()

            export_data = {
                "project": self.project_name,
                "exported_at": datetime.now().isoformat(),
                "collection": COLLECTION_NAME,
                "memories": []
            }

            for doc_id, doc, metadata in zip(
                results['ids'],
                results['documents'],
                results['metadatas']
            ):
                export_data["memories"].append({
                    "id": doc_id,
                    "document": doc,
                    "metadata": metadata
                })

            output_path = self.project_path / output_file
            with open(output_path, 'w') as f:
                json.dump(export_data, f, indent=2)

            print(f"{GREEN}✅ Exported {len(export_data['memories'])} memories to {output_file}{NC}")

        except Exception as e:
            print(f"{RED}❌ Error exporting memories: {e}{NC}")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Initialize ChromaDB project memory (stdio MCP mode)")
    parser.add_argument("--project", "-p", default=".", help="Project path (default: current directory)")
    parser.add_argument("--import-existing", action="store_true", help="Import existing decisions")
    parser.add_argument("--import-file", help="Specific file to import decisions from")
    parser.add_argument("--list", action="store_true", help="List all memories")
    parser.add_argument("--query", help="Query memories")
    parser.add_argument("--export", action="store_true", help="Export memories to JSON")
    parser.add_argument("--add", nargs=4, metavar=("DOCUMENT", "TYPE", "TAGS", "SOURCE"),
                       help="Add a memory: document type tags source")

    args = parser.parse_args()

    # Initialize
    initializer = ProjectMemoryInitializer(args.project)

    # Connect to ChromaDB
    if not initializer.connect():
        sys.exit(1)

    # Create or get collection
    if not initializer.create_or_get_collection():
        sys.exit(1)

    # Handle operations
    if args.list:
        initializer.list_all_memories()
    elif args.query:
        results = initializer.query_memories(args.query)
        if results and results['documents']:
            print(f"\n{BLUE}=== Query Results ==={NC}")
            for doc, metadata in zip(results['documents'][0], results['metadatas'][0]):
                print(f"📝 {doc}")
                print(f"   Type: {metadata.get('type', 'unknown')}, Tags: {metadata.get('tags', '')}")
    elif args.export:
        initializer.export_memories()
    elif args.add:
        doc, mem_type, tags, source = args.add
        memory_id = f"manual-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
        initializer.add_memory(doc, mem_type, tags, source, memory_id)
    elif args.import_existing:
        initializer.import_existing_decisions(args.import_file)
    else:
        # Default: just initialize
        print(f"\n{GREEN}✅ Project memory ready for {initializer.project_name}{NC}")
        print(f"Collection: {COLLECTION_NAME}")
        print(f"Memories: {initializer.collection.count()}")


if __name__ == "__main__":
    main()