# Agent Guidelines

## Build/Lint/Test Commands
- Validation: `just validate` (runs lint, check, verify-modules)
- Format: `just fmt` or `alejandra .`
- Lint: `just lint` or `statix check .`
- Check flake: `just check` or `nix flake check`
- Show outputs: `just show` or `nix flake show`
- Update dependencies: `just update` or `nix flake update`
- Full setup: `just setup` (update + format + test)

## Code Style
- Language: Nix expressions
- Formatter: alejandra (consistent spacing, alignment)
- Linter: statix (idioms, best practices, anti-patterns)
- Additional: deadnix (detect unused bindings)
- Indentation: 2 spaces
- Follow existing patterns in flake.nix for module structure
- Use `let...in` for local bindings
- Prefer explicit attribute sets over implicit
- No inline comments unless documenting complex logic

## Testing
- Do validations via `just validate`
- Manual testing requires NixOS environment
