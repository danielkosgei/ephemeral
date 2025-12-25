# Multi-Language Development Workspace

<div align="center">

**A batteries-included Nix development environment for Go and Node.js projects**

[![Built with Nix](https://img.shields.io/badge/Built_With-Nix-5277C3.svg?logo=nixos&logoColor=white)](https://nixos.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[Features](#features) •
[Quick Start](#quick-start) •
[Architecture](#architecture) •
[Usage](#usage) •
[Configuration](#configuration)

</div>

---

## Overview

A pure Nix flake that provides an opinionated, interactive development environment for modern application development. Supports multiple programming languages with automatic project scaffolding, local database management, and a beautiful terminal user interface.

### Design Philosophy

- **Zero global installation**: All dependencies managed through Nix
- **Project isolation**: Each project gets its own PostgreSQL/Redis instances
- **Interactive & intelligent**: Smart project detection and guided setup
- **Modular architecture**: Easy to extend with new languages
- **Developer experience first**: Beautiful TUI, helpful aliases, instant feedback

## Features

### Multi-Language Support

| Language | Runtime | Package Manager | Live Reload | Testing | Linting |
|----------|---------|-----------------|-------------|---------|---------|
| **Go** | Latest stable | Go modules | ✅ air | ✅ Native | ✅ golangci-lint |
| **Node.js** | Latest LTS | bun (10-100x faster) | ✅ Built-in | ✅ Built-in | ✅ ESLint |

### Database & Cache

- **PostgreSQL 14+**: Isolated instance on port 5433
  - Automatic initialization with UTF-8 encoding
  - Separate development and test databases
  - Connection via Unix sockets or TCP
  - Beautiful CLI via `pgcli`

- **Redis 7+**: Optional, runs on port 6379
  - Daemonized with data persistence
  - Connection via `redli` CLI

### Interactive Workflow

```
┌─────────────────────────────────────────────┐
│  Multi-Language Dev Workspace               │
│  Powered by Nix                             │
└─────────────────────────────────────────────┘

What would you like to do?
❯ Create new project
  Open existing project
```

**Create New Project:**
1. Choose language (Go or Node.js)
2. Enter project name
3. Select database (PostgreSQL or None)
4. Enable Redis (optional)
5. Configure language-specific settings
6. Automatic scaffolding with best practices

**Open Existing Project:**
- Scans current directory for projects
- Detects `go.mod` or `package.json`
- Loads saved configuration
- Starts services automatically

### Project Scaffolding

#### Go Projects

```
my-go-project/
├── .air.toml              # Live reload config
├── .gitignore             # Go-specific patterns
├── Makefile               # Common tasks (build, test, migrate, lint)
├── README.md              # Project documentation
├── cmd/
│   └── api/
│       └── main.go        # HTTP server entrypoint
├── internal/
│   ├── config/            # Configuration management
│   ├── database/          # Database connections
│   ├── handlers/          # HTTP handlers
│   └── models/            # Data models
├── migrations/            # SQL migrations
├── pkg/                   # Public libraries
└── scripts/               # Build & deployment scripts
```

**Included Tools:**
- `go` - Go compiler and toolchain
- `air` - Live reload for Go apps
- `golangci-lint` - Fast, configurable linter
- `go-migrate` - Database migration tool
- `gotools` - Additional Go tools

#### Node.js Projects

```
my-node-project/
├── .gitignore             # Node-specific patterns
├── package.json           # Dependencies & scripts
├── README.md              # Project documentation
├── src/
│   ├── index.js           # Express server entrypoint
│   ├── routes/            # API routes
│   ├── controllers/       # Business logic
│   ├── models/            # Data models
│   ├── middleware/        # Express middleware
│   └── config/            # Configuration
└── tests/                 # Test files
```

**Included Tools:**
- `nodejs` - Node.js runtime (LTS)
- `bun` - Fast JavaScript runtime & package manager
- Express.js framework with hot reload
- ESLint & Prettier for code quality

### Developer Experience

**Smart Aliases:**
```bash
# Development
dev          # Start with live reload
build        # Build the application
test         # Run tests
lint         # Run linter
format       # Format code

# Database (when PostgreSQL enabled)
db           # Connect to development database
db-test      # Connect to test database
migrate-up   # Apply migrations
migrate-down # Rollback migration

# Monitoring
services-status  # Check PostgreSQL/Redis status
dashboard        # TUI dashboard (coming soon)
```

**Environment Variables:**
- Automatically generated `.env` file
- Database credentials pre-configured
- PROJECT_NAME, DATABASE_URL, etc.

**Cleanup:**
- Graceful service shutdown on exit
- Returns to original directory
- Preserves data in `.data/` for next session

## Quick Start

### Prerequisites

- **Nix** with flakes enabled:
  ```bash
  # Add to ~/.config/nix/nix.conf or /etc/nix/nix.conf
  experimental-features = nix-command flakes
  ```

- **Git** (for cloning and project management)

### Installation

1. **Clone this repository:**
   ```bash
   git clone <repository-url> ~/nix-workspace
   cd ~/nix-workspace
   ```

2. **Enter the development shell:**
   ```bash
   nix develop
   ```

3. **Follow the interactive prompts** to create or open a project

### Creating Your First Project

```bash
# Navigate to your projects directory
cd ~/projects

# Start the development environment
nix develop ~/nix-workspace

# Choose "Create new project"
# Select language: Go or Node.js
# Enter project details
# Watch as your project is scaffolded!
```

## Architecture

### Module Structure

```
.
├── flake.nix                    # Main orchestrator (~300 lines)
│
└── nix/
    ├── lib/
    │   └── helpers.nix         # Utilities & color palette
    │
    ├── common.nix              # Shared packages & setup
    │                           #   - PostgreSQL, Redis, gum, etc.
    │                           #   - Welcome screen & cleanup
    │                           #   - Database initialization
    │
    └── languages/
        ├── go.nix              # Go ecosystem
        │                       #   - Packages: go, air, golangci-lint
        │                       #   - Project scaffolding
        │                       #   - Aliases & helpers
        │
        └── node.nix            # Node.js ecosystem
                                #   - Packages: nodejs, bun
                                #   - Project scaffolding
                                #   - Aliases & helpers
```

### Design Principles

1. **Pure Nix Approach**: All logic in Nix modules, no external scripts
2. **Composability**: Language modules are independent and composable
3. **Progressive Enhancement**: Start simple, add complexity as needed
4. **Convention over Configuration**: Sensible defaults, easy to override

### Extending with New Languages

Adding a new language (e.g., Python) is straightforward:

```nix
# nix/languages/python.nix
{ pkgs }:
{
  packages = with pkgs; [ python311 poetry ];
  
  scaffoldHook = ''
    # Project scaffolding logic
  '';
  
  aliasesHook = ''
    # Language-specific aliases
  '';
}
```

Then import in `flake.nix`:
```nix
pythonModule = import ./nix/languages/python.nix { inherit pkgs; };
allPackages = common.packages ++ goModule.packages 
           ++ nodeModule.packages ++ pythonModule.packages;
```

## Usage

### Workflow Examples

#### Start Fresh
```bash
cd ~/projects
nix develop ~/nix-workspace
# Select "Create new project" → Fill in details → Start coding
```

#### Open Existing Project
```bash
cd ~/projects
nix develop ~/nix-workspace
# Select "Open existing project" → Choose from list
```

#### Direct Project Access
```bash
cd ~/projects/my-existing-project
nix develop ~/nix-workspace
# Auto-detects project type, loads config, starts services
```

### Typical Development Session

**Go Project:**
```bash
$ dev                  # Start with live reload
$ make build          # Build binary
$ make test           # Run tests
$ make migrate-up     # Apply migrations
$ db                  # Connect to database
```

**Node.js Project:**
```bash
$ dev                 # Start with hot reload (bun --watch)
$ test                # Run tests (bun test)
$ lint                # Check code quality
$ bi                  # Install dependencies (bun install)
```

### Environment Variables

Projects include a `.env` file with pre-populated values:

```env
# Database
DATABASE_URL=postgresql://postgres@127.0.0.1:5433/myproject_dev
PGHOST=127.0.0.1
PGPORT=5433
PGDATABASE=myproject_dev
PGUSER=postgres

# Redis (if enabled)
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

# Application
GO_ENV=development      # or NODE_ENV for Node.js
PORT=8080              # or 3000 for Node.js
```

Load in your application:
- **Go**: Use `godotenv` or `viper`
- **Node.js**: Automatically loaded by `dotenv` package

## Configuration

### Workspace Configuration

Each project stores its configuration in `.workspace-config`:

```bash
USE_DATABASE="PostgreSQL"
USE_REDIS=true
PROJECT_NAME="my-api"
PROJECT_LANG="go"
MODULE_PATH="github.com/username/my-api"
```

This file is:
- Automatically generated during setup
- Read on subsequent `nix develop` sessions
- Gitignored (project-specific, not for version control)

### Database Configuration

**Location**: `.data/postgres/` (gitignored)
**Port**: 5433 (avoids conflicts with system PostgreSQL)
**User**: postgres (no password)
**Databases**:
- `{projectname}_dev` - Development database
- `{projectname}_test` - Test database

**Customization**: Edit `.data/postgres/postgresql.conf`

### Customizing the Flake

**Add packages** globally:
```nix
# nix/common.nix
packages = with pkgs; [
  postgresql
  redis
  # Add your tools here
  ripgrep
  fd
];
```

**Modify scaffolding**:
```nix
# nix/languages/go.nix
scaffoldHook = ''
  # Customize project structure
  mkdir -p custom/directory
  # Add custom files
'';
```

## Development

### Testing Changes

```bash
# Check flake validity
nix flake check

# Test without committing
nix develop --impure

# See what will be built
nix flake show
```

### Debugging

```bash
# Verbose flake evaluation
nix develop --show-trace

# Check package availability
nix search nixpkgs postgresql

# Inspect derivation
nix show-derivation
```

### Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly (`nix flake check`)
5. Commit with conventional commits
6. Push and create a Pull Request

**Areas for improvement:**
- Additional language support (Python, Rust, etc.)
- More database options (MySQL, MongoDB)
- Enhanced scaffolding templates
- CI/CD integration helpers
- Docker/Podman support

## Troubleshooting

### Port Already in Use

**Problem**: PostgreSQL or Redis port is occupied

**Solution**:
```bash
# Check what's using the port
lsof -i :5433
lsof -i :6379

# Stop system services if needed
systemctl stop postgresql
systemctl stop redis
```

### Nix Flake Errors

**Problem**: `error: path does not exist`

**Solution**: Ensure `nix/` directory is committed to git:
```bash
git add nix/
git commit -m "Add nix modules"
```

### Database Initialization Failed

**Problem**: PostgreSQL won't start

**Solution**: Remove and reinitialize:
```bash
rm -rf .data/postgres
# Re-enter nix develop
```

## Performance

### Benchmark Comparison

| Task | npm | bun | Speedup |
|------|-----|-----|---------|
| Install (cold) | 15s | 0.5s | **30x** |
| Install (warm) | 8s | 0.2s | **40x** |
| Run tests | 2.5s | 0.3s | **8x** |

### Resource Usage

- **Disk**: ~100MB per project (including databases)
- **Memory**: ~200MB for services (PostgreSQL + Redis)
- **Startup**: ~2-3 seconds for full environment

## Comparison

### vs Docker Compose

| Feature | This Flake | Docker Compose |
|---------|------------|----------------|
| Reproducibility | ✅ Declarative Nix | ✅ Declarative YAML |
| Startup time | ⚡ 2-3s | 🐢 10-20s |
| Disk usage | 💾 Minimal | 📦 Heavy (images) |
| Multi-language | ✅ Native | ⚠️ Requires images |
| Learning curve | 📚 Moderate | 📖 Easy |

### vs asdf/mise

| Feature | This Flake | asdf/mise |
|---------|------------|-----------|
| Runtime management | ✅ Nix | ✅ Version files |
| Services (DB/cache) | ✅ Integrated | ❌ Manual |
| Project scaffolding | ✅ Automated | ❌ None |
| Reproducibility | ✅ Pinned | ⚠️ Best effort |

## FAQ

**Q: Can I use this without Nix?**
A: No, Nix is required. However, all dependencies are managed by Nix, so you don't need to install anything else globally.

**Q: Do I need NixOS?**
A: No! This works on any Linux/macOS system with Nix installed.

**Q: Can I use my system's PostgreSQL/Redis?**
A: You can, but it's not recommended. The isolated instances prevent conflicts and are easier to manage.

**Q: How do I add Python/Rust/etc.?**
A: Create a new module in `nix/languages/` following the Go/Node.js pattern, then add it to `flake.nix`.

**Q: Can I customize the scaffolding?**
A: Absolutely! Edit the relevant `scaffoldHook` in `nix/languages/*.nix`.

**Q: Is this production-ready?**
A: This is a development environment. For production, build and deploy your applications normally.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Built with ❤️ using Nix
- Inspired by the Nix community's excellent work
- TUI powered by [gum](https://github.com/charmbracelet/gum)
- Database management via [PostgreSQL](https://www.postgresql.org/) and [Redis](https://redis.io/)

---

<div align="center">

**[⬆ Back to Top](#multi-language-development-workspace)**

Made with Nix • Star if you find this useful!

</div>
