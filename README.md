# Advanced Roblox Setup

A comprehensive Roblox development environment using TypeScript, modern tooling, and industry-standard workflows.

## Overview

This project provides a professional Roblox development setup that combines TypeScript development with Roblox's native tools. It enables developers to leverage the TypeScript ecosystem while maintaining full compatibility with Roblox Studio.

## Tools & Technologies

### Core Development Tools

- **[roblox-ts](https://github.com/roblox-ts/roblox-ts)** - TypeScript compiler for Roblox, allowing TypeScript development with Roblox APIs
- **[Rojo](https://github.com/rojo-rbx/rojo)** - Project management tool that separates game development from Roblox Studio
- **[Lune](https://github.com/lune-org/lune)** - Asset fetching tool that pulls builds from Roblox Studio into the codebase
- **[Asphalt](https://github.com/jackTabsCode/asphalt)** - Asset management for uploading/pulling asset references (images, audio, models, animations)
- **[rbxcloud](https://github.com/Sleitnick/rbxcloud)** - GitHub Actions for continuous deployment workflows

### Build & Tool Management

- **[Rokit](https://github.com/rojo-rbx/rokit)** - Tool manager for coordinating all Roblox development tools

## Project Structure

```
advanced-roblox-setup/
├── src/
│   ├── client/          # Client-side TypeScript code
│   ├── server/          # Server-side TypeScript code
│   └── shared/          # Shared code between client and server
├── assets/
│   ├── content/         # Asphalt asset folder (images, audio, videos, models, animations)
│   ├── Workspace.rbxm   # Game workspace model
│   ├── Lighting.rbxm    # Lighting configuration
│   ├── replicated-storage-models/  # Shared models
│   └── server-storage-models/      # Server-only models
├── generated/           # Auto-generated files
│   ├── assets.d.ts      # TypeScript type definitions
│   └── assets.luau      # Lua asset references
├── out/                 # Compiled Roblox Lua output
├── include/             # Roblox TypeScript definitions
├── lune/                # Lune scripts for asset management
└── Configuration files  # tsconfig.json, .eslintrc, etc.
```

## Installation

### Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- Roblox Studio (for asset management)

### Setup Steps

1. **Install dependencies**

    ```bash
    npm install
    ```

2. **Install build tools via Rokit**

    ```bash
    rokit install
    ```

3. **Configure environment variables**
    - Copy `.env.example` to `.env`
    - Set your API keys and place IDs

4. **Initialize project**

    ```bash
    npm run build
    ```

    This command runs ESLint checks and compiles TypeScript to Roblox Lua code.

## Development Workflow

### Development Server

Run these commands in separate terminals as they are continuous processes:

```bash
# Terminal 1: Watch for changes (development mode)
npm run watch

# Terminal 2: Serve Roblox project
rojo serve
```

### Code Quality

The project includes ESLint and Prettier for code quality and style enforcement:

```bash
# Check for linting errors
npm run lint

# Auto-fix linting errors
npm run lint:fix

# Format code with Prettier
npm run format

# Check code formatting without making changes
npm run format:check
```

**Build Process:**

```bash
# Compile TypeScript to Roblox Lua
npm run build
```

This command runs ESLint checks and compiles TypeScript to Roblox Lua code.

### Asset Management

#### Lune - Workspace & Lighting Configuration

Use Lune to pull assets from Roblox Studio:

```bash
# Download using place ID from .env
lune run ./lune/fetch-assets

# Download with specific place ID
lune run ./lune/fetch-assets --place-id <id>

# Download from local file
lune run ./lune/fetch-assets --file <path>
```

**Supported Assets:**

- Workspace configuration & models
- Lighting configuration
- Shared models
- Server models

#### Asphalt - Asset Upload & Reference Management

Asphalt manages images, videos, audio, and other asset types:

```bash
asphalt sync
```

Asphalt uploads these assets to Roblox and collects their reference IDs into generated scripts for use in your project.

## Resources

- [roblox-ts Documentation](https://roblox-ts.com/)
- [Rojo Documentation](https://rojo.space/)
- [Lune Documentation](https://lune-org.github.io/lune/)
- [Asphalt Documentation](https://github.com/jackTabsCode/asphalt)
- [rbxcloud Documentation](https://github.com/Sleitnick/rbxcloud)
- [Roblox Developer Hub](https://create.roblox.com/)
