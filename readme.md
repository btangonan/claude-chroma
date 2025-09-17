To run that script from a new directory in terminal:

  # Option 1: Run with full path (quotes needed for spaces)
  "/Users/bradleytangonan/Desktop/my apps/ats_resume/chromadb_setup_v4_rollback.sh"

  # Option 2: For a specific project name
  "/Users/bradleytangonan/Desktop/my apps/ats_resume/chromadb_setup_v4_rollback.sh" "my_project"

  # Option 3: With project name and parent directory
  "/Users/bradleytangonan/Desktop/my apps/ats_resume/chromadb_setup_v4_rollback.sh" "my_project"
  "/path/to/parent"

  # Option 4: Non-interactive mode (auto-yes to all prompts)
  CHROMA_SETUP_YES=1 "/Users/bradleytangonan/Desktop/my apps/ats_resume/chromadb_setup_v4_rollback.sh"

  # Option 5: Auto-install shell function without prompting
  CHROMA_SETUP_ADD_SHELL_FN=1 "/Users/bradleytangonan/Desktop/my apps/ats_resume/chromadb_setup_v4_rollback.sh"

  Note: The quotes around the path are required because of the space in "my apps".

  If you run it without arguments, it will:
  1. Ask for project name (or use current directory if blank)
  2. Ask for parent directory (defaults to ~/Projects)
  3. Set up ChromaDB in that location
