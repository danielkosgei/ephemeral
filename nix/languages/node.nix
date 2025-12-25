{ pkgs }:
{
  # Node.js-specific packages
  packages = with pkgs; [
    nodejs
    nodePackages.npm
  ];
  
  # Node.js project scaffolding
  scaffoldHook = ''
    if [ "$IS_EXISTING_PROJECT" = false ] && [ "$PROJECT_LANG" = "node" ]; then
      gum style --foreground "$LAVENDER" "📦 Creating Node.js project structure..."
      
      # Create package.json
      if [ ! -f "package.json" ]; then
        cat > package.json << PACKAGE_EOF
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "A Node.js application built with Nix development environment",
  "main": "src/index.js",
  "scripts": {
    "dev": "nodemon src/index.js",
    "start": "node src/index.js",
    "test": "jest",
    "lint": "eslint src/",
    "format": "prettier --write ."
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "devDependencies": {
    "nodemon": "^3.0.0",
    "eslint": "^8.0.0",
    "prettier": "^3.0.0",
    "jest": "^29.0.0"
  },
  "dependencies": {
    "express": "^4.18.0",
    "dotenv": "^16.0.0"
  }
}
PACKAGE_EOF
      fi
      
      # Create .gitignore
      if [ ! -f ".gitignore" ]; then
        cat > .gitignore << 'GITIGNORE_EOF'
# Dependencies
node_modules/
package-lock.json
yarn.lock

# Build output
dist/
build/

# Logs
logs/
*.log
npm-debug.log*

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

# OS
.DS_Store
Thumbs.db

# Testing
coverage/
.nyc_output/
GITIGNORE_EOF
      fi
      
      # Create project structure
      mkdir -p src/{routes,controllers,models,middleware,config}
      mkdir -p tests
      
      # Create src/index.js
      if [ ! -f "src/index.js" ]; then
        cat > src/index.js << 'INDEX_EOF'
require('dotenv').config();
const express = require('express');
const app = express();

const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'Hello from Node.js!' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;
INDEX_EOF
      fi
      
      # Create README.md
      if [ ! -f "README.md" ]; then
        cat > README.md << README_EOF
# $PROJECT_NAME

A Node.js application built with Nix development environment.

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
npm install
\\\`\\\`\\\`

Run the development server:

\\\`\\\`\\\`bash
npm run dev
\\\`\\\`\\\`

### Production

\\\`\\\`\\\`bash
npm start
\\\`\\\`\\\`

### Testing

\\\`\\\`\\\`bash
npm test
\\\`\\\`\\\`

## Available Commands

- \\\`npm run dev\\\` - Start development server with hot reload
- \\\`npm start\\\` - Start production server
- \\\`npm test\\\` - Run tests
- \\\`npm run lint\\\` - Run linter
- \\\`npm run format\\\` - Format code with Prettier
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
NODE_ENV=development
PORT=3000

# Timezone
TZ=UTC
ENV_EOF
      
      gum style --foreground "#b4f8c8" "✓ Node.js project structure created!"
      gum style --foreground "#ffb6b9" --margin "0 2" "📝 Created .env file with database credentials"
      
      # Prompt to install dependencies
      echo ""
      if gum confirm "Would you like to install npm dependencies now?"; then
        npm install
      fi
    fi
  '';
  
  # Node.js-specific aliases
  aliasesHook = ''
    if [ "$PROJECT_LANG" = "node" ]; then
      # Development
      alias dev='npm run dev'
      alias start='npm start'
      alias test='npm test'
      alias lint='npm run lint'
      alias format='npm run format'
      
      # Package management
      alias ni='npm install'
      alias nid='npm install --save-dev'
      alias nu='npm update'
    fi
  '';
}
