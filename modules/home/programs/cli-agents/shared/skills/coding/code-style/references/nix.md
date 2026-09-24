# Nix

## 2026-09-24: Single-attribute sets

- Use dotted attribute paths for a set containing only one assignment: `_1password.enable = true;`, not `_1password = { enable = true; };`.
- Collapse singleton chains. Keep braces where multiple related attributes are grouped.
- Preserve recursive sets, `inherit`, comments, and expression boundaries when flattening would change semantics or lose information. Do not flatten sets passed as function arguments or stored in lists.

```nix
programs = {
  _1password.enable = true;
  _1password-gui = {
    enable = true;
    polkitPolicyOwners = [user];
  };
};
```

In dotfiles-nix, `ast-grep scan` enforces this for directly assigned, comment-free, non-recursive singleton sets. It also runs as the `nix-single-attribute` pre-commit hook. Use `ast-grep scan --update-all` to fix findings, then format with Alejandra. Repeat for nested singleton chains.
