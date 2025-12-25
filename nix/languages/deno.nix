{ pkgs }:
{
  # Deno-specific packages
  packages = with pkgs; [
    deno
  ];
  
  # Deno project scaffolding
  scaffoldHook = ''
    if [ "$IS_EXISTING_PROJECT" = false ] && [ "$PROJECT_LANG" = "deno" ]; then
      gum style --foreground "$LAVENDER" "📦 Creating Deno (TypeScript) project structure..."
      
      # Create deno.json
      cat > deno.json << 'DENO_EOF'
{
  "tasks": {
    "dev": "deno run --watch --allow-net --allow-read --allow-env src/main.ts",
    "start": "deno run --allow-net --allow-read --allow-env src/main.ts",
    "test": "deno test --allow-net --allow-read --allow-env"
  },
  "imports": {
    "@oak/oak": "jsr:@oak/oak@^17",
    "@std/dotenv": "jsr:@std/dotenv@^0.225"
  },
  "fmt": {
    "useTabs": false,
    "lineWidth": 100,
    "indentWidth": 2,
    "semiColons": true,
    "singleQuote": false,
    "proseWrap": "preserve"
  },
  "lint": {
    "rules": {
      "tags": ["recommended"]
    }
  }
}
DENO_EOF
      
      # Create .gitignore
      cat > .gitignore << 'GITIGNORE_EOF'
# Deno
.deno/

# Data directories
.data/

# Environment files
.env
.env.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store
GITIGNORE_EOF
      
      # Create project structure
      mkdir -p src/{routes,middleware,models}
      mkdir -p tests
      
      # Create src/main.ts
      cat > src/main.ts << 'MAIN_EOF'
import { Application, Router } from "@oak/oak";
import { load } from "@std/dotenv";

// Load environment variables
await load({ export: true });

const router = new Router();

router
  .get("/", (ctx) => {
    ctx.response.body = { message: "Hello from Deno!" };
  })
  .get("/health", (ctx) => {
    ctx.response.body = { status: "ok" };
  });

const app = new Application();

// Logger middleware
app.use(async (ctx, next) => {
  await next();
  const rt = ctx.response.headers.get("X-Response-Time");
  console.log(`''${ctx.request.method} ''${ctx.request.url} - ''${rt}`);
});

// Timing middleware
app.use(async (ctx, next) => {
  const start = Date.now();
  await next();
  const ms = Date.now() - start;
  ctx.response.headers.set("X-Response-Time", `''${ms}ms`);
});

app.use(router.routes());
app.use(router.allowedMethods());

const port = parseInt(Deno.env.get("PORT") || "8000");
console.log(`Server listening on http://localhost:''${port}`);

await app.listen({ port });
MAIN_EOF
      
      # Create tests/main_test.ts
      cat > tests/main_test.ts << 'TEST_EOF'
import { assertEquals } from "jsr:@std/assert";

Deno.test("example test", () => {
  assertEquals(1 + 1, 2);
});
TEST_EOF
      
      # Create README.md
      cat > README.md << README_EOF
# $PROJECT_NAME

A Deno (TypeScript) application built with Nix development environment.

## Getting Started

### Prerequisites

- Nix with flakes enabled

### Development

Enter the development environment:

\\\`\\\`\\\`bash
nix develop
\\\`\\\`\\\`

Run the development server:

\\\`\\\`\\\`bash
deno task dev
\\\`\\\`\\\`

Or using the alias:

\\\`\\\`\\\`bash
dev
\\\`\\\`\\\`

### Testing

\\\`\\\`\\\`bash
deno task test
\\\`\\\`\\\`

### Code Quality

Format code:
\\\`\\\`\\\`bash
deno fmt
\\\`\\\`\\\`

Lint code:
\\\`\\\`\\\`bash
deno lint
\\\`\\\`\\\`

## Available Commands

- \\\`dev\\\` - Start development server with hot reload
- \\\`start\\\` - Start production server
- \\\`test\\\` - Run tests
- \\\`lint\\\` - Run linter
- \\\`format\\\` - Format code
README_EOF
      
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
DENO_ENV=development
PORT=8000

# Timezone
TZ=UTC
ENV_EOF
      
      gum style --foreground "#b4f8c8" "✓ Deno project structure created!"
      gum style --foreground "#ffb6b9" --margin "0 2" "📝 Created .env file with database credentials"
    fi
  '';
  
  # Deno-specific aliases
  aliasesHook = ''
    if [ "$PROJECT_LANG" = "deno" ]; then
      # Development
      alias dev='deno task dev'
      alias start='deno task start'
      alias test='deno task test'
      alias lint='deno lint'
      alias format='deno fmt'
      
      # Deno utilities
      alias dcheck='deno check src/main.ts'
      alias dcache='deno cache --reload'
    fi
  '';
}
