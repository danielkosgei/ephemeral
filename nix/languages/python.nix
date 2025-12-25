{ pkgs }:
{
  # Python-specific packages
  packages = with pkgs; [
    python312
    poetry
    ruff  # Fast Python linter/formatter
    black
  ];
  
  # Python project scaffolding
  scaffoldHook = ''
    if [ "$IS_EXISTING_PROJECT" = false ] && [ "$PROJECT_LANG" = "python" ]; then
      gum style --foreground "$LAVENDER" "📦 Creating Python project structure..."
      
      # Create pyproject.toml
      if [ ! -f "pyproject.toml" ]; then
        cat > pyproject.toml << 'PYPROJECT_EOF'
[tool.poetry]
name = "$PROJECT_NAME"
version = "0.1.0"
description = "A Python application built with Nix development environment"
authors = ["Your Name <you@example.com>"]
readme = "README.md"
packages = [{include = "$PROJECT_NAME", from = "src"}]

[tool.poetry.dependencies]
python = "^3.12"
fastapi = "^0.115.0"
uvicorn = {extras = ["standard"], version = "^0.34.0"}
pydantic = "^2.10.0"
python-dotenv = "^1.0.0"

[tool.poetry.group.dev.dependencies]
pytest = "^8.3.0"
pytest-asyncio = "^0.24.0"
httpx = "^0.27.0"
ruff = "^0.8.0"
black = "^24.0.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"

[tool.ruff]
line-length = 100
target-version = "py312"

[tool.black]
line-length = 100
target-version = ["py312"]

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
PYPROJECT_EOF
      fi
      
      # Create .gitignore
      if [ ! -f ".gitignore" ]; then
        cat > .gitignore << 'GITIGNORE_EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python

# Virtual environments
venv/
env/
ENV/
.venv

# Poetry
poetry.lock

# Distribution / packaging
dist/
build/
*.egg-info/

# Testing
.pytest_cache/
.coverage
htmlcov/

# Data directories
.data/

# Environment files
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Type checking
.mypy_cache/
.pytype/
GITIGNORE_EOF
      fi
      
      # Create project structure
      PROJECT_MODULE=$(echo "$PROJECT_NAME" | tr '-' '_')
      mkdir -p src/''${PROJECT_MODULE}/{api,models,services}
      mkdir -p tests
      
      # Create src/__init__.py
      touch src/''${PROJECT_MODULE}/__init__.py
      
      # Create src/main.py
      if [ ! -f "src/''${PROJECT_MODULE}/main.py" ]; then
        cat > src/''${PROJECT_MODULE}/main.py << 'MAIN_EOF'
import os
from typing import Dict

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Load environment variables
load_dotenv()

# Create FastAPI app
app = FastAPI(
    title="API",
    description="Built with FastAPI and Nix",
    version="0.1.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root() -> Dict[str, str]:
    """Root endpoint"""
    return {"message": "Hello from Python!"}

@app.get("/health")
async def health() -> Dict[str, str]:
    """Health check endpoint"""
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=True,
        log_level="info"
    )
MAIN_EOF
      fi
      
      # Create tests/__init__.py
      touch tests/__init__.py
      
      # Create tests/test_main.py
      if [ ! -f "tests/test_main.py" ]; then
        cat > tests/test_main.py << 'TEST_EOF'
from fastapi.testclient import TestClient
from src.''${PROJECT_MODULE}.main import app

client = TestClient(app)

def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Hello from Python!"}

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
TEST_EOF
      fi
      
      # Create README.md
      if [ ! -f "README.md" ]; then
        cat > README.md << README_EOF
# $PROJECT_NAME

A Python FastAPI application built with Nix development environment.

## Getting Started

### Prerequisites

- Nix with flakes enabled

### Development

Enter the development environment:

\\\`\\\`\\\`bash
nix develop
\\\`\\\`\\\`

Install dependencies:

\\\`\\\`\\\`bash
poetry install
\\\`\\\`\\\`

Run the development server:

\\\`\\\`\\\`bash
poetry run dev
\\\`\\\`\\\`

Or using the alias:

\\\`\\\`\\\`bash
dev
\\\`\\\`\\\`

### Testing

\\\`\\\`\\\`bash
poetry run pytest
\\\`\\\`\\\`

Or using the alias:

\\\`\\\`\\\`bash
test
\\\`\\\`\\\`

### Code Quality

Format code:
\\\`\\\`\\\`bash
poetry run black .
poetry run ruff check --fix .
\\\`\\\`\\\`

Or using aliases:
\\\`\\\`\\\`bash
format
lint
\\\`\\\`\\\`

## Available Commands

- \\\`dev\\\` - Start development server with hot reload
- \\\`test\\\` - Run tests
- \\\`lint\\\` - Run linter
- \\\`format\\\` - Format code with Black
- \\\`pi\\\` - Install dependencies (poetry install)
- \\\`pa\\\` - Add package (poetry add)
- \\\`pad\\\` - Add dev package (poetry add --group dev)
README_EOF
      fi
      
      # Save workspace configuration
      cat > .workspace-config << CONFIG_EOF
USE_DATABASE="$USE_DATABASE"
USE_REDIS=$USE_REDIS
PROJECT_NAME="$PROJECT_NAME"
PROJECT_LANG="$PROJECT_LANG"
CONFIG_EOF
      
      # Create .env file
      cat > .env << ENV_EOF
# Database Configuration
DATABASE_URL=$DATABASE_URL
PGHOST=$PGHOST
PGPORT=$PGPORT
PGDATABASE=$PGDATABASE
PGUSER=$PGUSER
PGPASSWORD=$PGPASSWORD

# Redis Configuration
REDIS_HOST=$REDIS_HOST
REDIS_PORT=$REDIS_PORT

# Application
PYTHON_ENV=development
PORT=8000

# Timezone
TZ=UTC
ENV_EOF
      
      gum style --foreground "#b4f8c8" "✓ Python project structure created!"
      gum style --foreground "#ffb6b9" --margin "0 2" "📝 Created .env file with database credentials"
      
      # Prompt to install dependencies
      echo ""
      if gum confirm "Would you like to install dependencies now?"; then
        poetry install
      fi
    fi
  '';
  
  # Python-specific aliases
  aliasesHook = ''
    if [ "$PROJECT_LANG" = "python" ]; then
      # Find the actual module name in src/
      PYTHON_MODULE=$(ls -d src/*/ 2>/dev/null | head -n1 | xargs basename 2>/dev/null || echo "unknown")
      
      # Development
      alias dev="poetry run uvicorn src.''${PYTHON_MODULE}.main:app --reload --host 0.0.0.0 --port ''${PORT:-8000}"
      alias test='poetry run pytest'
      alias lint='poetry run ruff check .'
      alias format='poetry run black . && poetry run ruff check --fix .'
      
      # Package management
      alias pi='poetry install'
      alias pa='poetry add'
      alias pad='poetry add --group dev'
      alias pr='poetry remove'
      alias pu='poetry update'
      
      # Poetry shell
      alias pshell='poetry shell'
    fi
  '';
}
