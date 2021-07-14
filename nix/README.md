# Nix

Nix support for development and CI of RAPcores.

## NPM
```
nix-shell -p nodePackages.node2nix
node2nix -i node-packages.json
```

Source of truth: node-packages.json

## Python

Using mach-nix. The dependencies are automatically installed using the
requirements.txt found in ./docs.


