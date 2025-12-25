{ pkgs }:
{
  # Go-specific packages
  packages = with pkgs; [
    go
    gotools
    golangci-lint
    go-migrate
    air
  ];
  
  # Go project scaffolding
  scaffoldHook = ''
    if [ "$IS_EXISTING_PROJECT" = false ] && [ "$PROJECT_LANG" = "go" ]; then
      gum style --foreground "$LAVENDER" "📦 Creating Go project structure..."
      
      # Initialize go.mod
      if [ ! -f "go.mod" ]; then
        go mod init "$MODULE_PATH" > /dev/null 2>&1
      fi
      
      # Create .gitignore
      if [ ! -f ".gitignore" ]; then
        cat > .gitignore << 'GITIGNORE_EOF'
# Binaries
bin/
*.exe
*.exe~
*.dll
*.so
*.dylib
*.test
*.out

# Go workspace
go.work

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

# OS
.DS_Store
Thumbs.db
GITIGNORE_EOF
      fi
      
      # Create Makefile
      if [ ! -f "Makefile" ]; then
        cat > Makefile << MAKEFILE_EOF
.PHONY: help build run test clean dev migrate-up migrate-down migrate-create

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo
	@echo 'Available targets:'
	@egrep '^[a-zA-Z_-]+:.*?## .*\$\$' \$(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \\033[36m%-15s\\033[0m %s\\n", \$\$1, \$\$2}'

build: ## Build the application
	@echo "Building..."
	@mkdir -p bin
	@go build -o bin/api ./cmd/api

run: ## Run the application
	@go run ./cmd/api

dev: ## Run with live reload (using air)
	@air

test: ## Run tests
	@go test -v ./...

test-coverage: ## Run tests with coverage
	@go test -v -coverprofile=coverage.out ./...
	@go tool cover -html=coverage.out

clean: ## Clean build artifacts
	@rm -rf bin/
	@rm -f coverage.out

migrate-up: ## Run database migrations
	@migrate -path ./migrations -database "\$\$DATABASE_URL" up

migrate-down: ## Rollback last migration
	@migrate -path ./migrations -database "\$\$DATABASE_URL" down 1

migrate-create: ## Create a new migration (usage: make migrate-create name=create_users)
	@migrate create -ext sql -dir ./migrations -seq \$(name)

tidy: ## Tidy and verify dependencies
	@go mod tidy
	@go mod verify

lint: ## Run linter
	@golangci-lint run

fmt: ## Format code
	@go fmt ./...
MAKEFILE_EOF
      fi
      
      # Create project structure
      mkdir -p cmd/api
      mkdir -p internal/{config,database,models,handlers}
      mkdir -p pkg
      mkdir -p scripts
      mkdir -p migrations
      
      # Create main.go
      if [ ! -f "cmd/api/main.go" ]; then
        cat > cmd/api/main.go << 'MAIN_EOF'
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello from Go! 🚀")
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status":"ok"}`)
	})

	log.Printf("Server starting on port %s...", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}
MAIN_EOF
      fi
      
      # Create .air.toml
      if [ ! -f ".air.toml" ]; then
        cat > .air.toml << 'AIR_EOF'
root = "."
testdata_dir = "testdata"
tmp_dir = "tmp"

[build]
  args_bin = []
  bin = "./tmp/main"
  cmd = "go build -o ./tmp/main ./cmd/api"
  delay = 1000
  exclude_dir = ["assets", "tmp", "vendor", ".data"]
  exclude_file = []
  exclude_regex = ["_test.go"]
  exclude_unchanged = false
  follow_symlink = false
  full_bin = ""
  include_dir = []
  include_ext = ["go", "tpl", "tmpl", "html"]
  include_file = []
  kill_delay = "0s"
  log = "build-errors.log"
  poll = false
  poll_interval = 0
  rerun = false
  rerun_delay = 500
  send_interrupt = false
  stop_on_error = false

[color]
  app = ""
  build = "yellow"
  main = "magenta"
  runner = "green"
  watcher = "cyan"

[log]
  main_only = false
  time = false

[misc]
  clean_on_exit = false

[screen]
  clear_on_rebuild = false
  keep_scroll = true
AIR_EOF
      fi
      
      # Create README.md
      if [ ! -f "README.md" ]; then
        cat > README.md << README_EOF
# $PROJECT_NAME

A Go application built with Nix development environment.

## Getting Started

### Prerequisites

- Nix with flakes enabled

### Development

Enter the development environment:

\\\`\\\`\\\`bash
nix develop
\\\`\\\`\\\`

Run the development server with live reload:

\\\`\\\`\\\`bash
make dev
\\\`\\\`\\\`

### Build

\\\`\\\`\\\`bash
make build
\\\`\\\`\\\`

### Testing

\\\`\\\`\\\`bash
make test
\\\`\\\`\\\`

## Available Commands

Run \\\`make help\\\` to see all available commands.
README_EOF
      fi
      
      # Save workspace configuration
      cat > .workspace-config << CONFIG_EOF
USE_DATABASE="$USE_DATABASE"
USE_REDIS=$USE_REDIS
PROJECT_NAME="$PROJECT_NAME"
PROJECT_LANG="$PROJECT_LANG"
MODULE_PATH="$MODULE_PATH"
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
GO_ENV=development
PORT=8080

# Timezone
TZ=UTC
ENV_EOF
      
      gum style --foreground "#b4f8c8" "✓ Go project structure created!"
      gum style --foreground "#ffb6b9" --margin "0 2" "📝 Created .env file with database credentials"
    fi
  '';
  
  # Go-specific aliases
  aliasesHook = ''
    if [ "$PROJECT_LANG" = "go" ]; then
      # Development
      alias dev='air'
      alias run='go run ./cmd/api'
      alias build='make build'
      alias test='go test ./...'
      alias test-v='go test -v ./...'
      alias coverage='go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out'
      
      # Code quality
      alias fmt='go fmt ./...'
      alias lint='golangci-lint run'
      alias tidy='go mod tidy && go mod verify'
    fi
  '';
}
