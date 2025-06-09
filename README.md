[![test](https://github.com/nicholaswmin/.dotfiles/actions/workflows/test.yml/badge.svg)](https://github.com/nicholaswmin/.dotfiles/actions/workflows/test.yml)

# .dotfiles

## quickstart

```bash
# Initialize repository
dotfiles init

# Link configuration files
dotfiles link ~/.zshrc
dotfiles link ~/.config/nvim

# Backup changes
dotfiles backup "Initial setup"
```

## Commands

- `dotfiles init [remote]` - Initialize dotfiles repository
- `dotfiles link <path>` - Link file or directory
- `dotfiles unlink <path>` - Unlink file or directory  
- `dotfiles restore` - Restore from remote repository
- `dotfiles backup [message]` - Commit and push changes

## Repository Structure

```
~/.dotfiles/
├── dotfiles             # Main CLI executable
├── install.sh           # macOS system setup
├── home/                # Mirror of $HOME structure
│   └── .config/         # Application configurations
│       └── macos/       # macOS-specific configs
├── config/macos/        # macOS-specific setup
├── tests/               # Comprehensive test suite
│   ├── main.test.sh     # Generator tests
│   ├── e2e.test.sh      # CLI functionality tests
│   └── run-all.sh       # Test runner
├── .github/workflows/   # CI/CD automation
└── _lib/                # Internal functions
```

## Installation

1. Add to PATH: `export PATH="/path/to/dotfiles:$PATH"`
2. Initialize: `dotfiles init`
3. Start linking: `dotfiles link ~/.zshrc`

## Testing

```bash
# Run all tests
./tests/run.test.sh

# Run individual test suites
./tests/main.test.sh    # Generator tests
./tests/e2e.test.sh     # CLI tests
```

> **note:** E2E tests only run on [CI](#CI/CD).   
> They are auto-skipped when testing locally.     
> This is intentional, to avoid mangling your user files.  

## macOS Integration

- System defaults optimization
- Homebrew package management
- Native macOS features

## CI/CD

CI is running on `arm64` macOS runners,    
on every push and pull request to `main` branch.

## License

MIT License
