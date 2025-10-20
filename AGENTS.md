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

## Changelog Practice
- **Always** create a changelog entry in `changelog/` for non-trivial changes
- Filename format: `YYYY-MM-DD-brief-description.md`
- Required sections:
  - **Date**: ISO format (YYYY-MM-DD)
  - **Summary**: 1-2 sentence overview
  - **Changes**: Detailed list of modifications
  - **Breaking Changes**: (if applicable) What breaks and why
  - **Migration Guide**: (if applicable) Before/after examples
  - **Rationale**: Why the changes were made
  - **Validation**: List passing checks (`just validate`, etc.)
  - **Files Modified/Created**: Complete list of affected files
- Use clear technical detail with code examples for complex changes
- Mark validation status with ✅ or ⚠️

## Documentation Review
- After making changes, review and update:
  - **README.md**: User-facing features, configuration examples, usage instructions
  - **AGENTS.md**: If build commands, style, or practices changed
  - **Module documentation**: NixOS option descriptions and examples
- Ensure examples in documentation match current API/options
- Remove outdated references to changed or removed features
- Add new features to appropriate documentation sections
