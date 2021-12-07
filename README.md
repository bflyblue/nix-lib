# nix-lib

Some useful functions I've made for myself.

## requirements

Helper for mach-nix requirements. It looks for includes of the form
"-r filename.txt" and recursively inlines them instead as mach-nix doesn't
currently support this feature.