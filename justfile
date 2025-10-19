# Nix dev templates justfile

# Show all available flake outputs
show:
  nix flake show

# Format all Nix files
fmt:
  alejandra .

# Check Nix files for issues
lint:
  statix check .

# Update flake.lock
update:
  nix flake update

# Check flake for errors without building
check:
  nix flake check

# Verify module syntax
verify-modules:
  nix eval '.#nixosModules.default' > /dev/null && echo "✓ Modules valid"

# Validate the project without updating dependencies
validate: lint check verify-modules
  @echo "✓ All validations passed"

# Full development setup
setup: update fmt validate
  @echo "✓ Setup complete"

# Help
help:
  @just --list
