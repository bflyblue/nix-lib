{ pkgs, lib }:

let lines = file: lib.splitString "\n" (builtins.readFile file);

    # Very simple test to look for lines starting with -r
    isRequire = lib.hasPrefix "-r ";

    # Very simple way to extract filename from a -r line
    requireFile = dir: file: "${dir}/${lib.removePrefix "-r " file}";

    # Return list of lines from a requirements file, resursively including
    # files included using -r
    requires = file:
      let part = lib.partition isRequire (lines file); # right = -r lines, wrong = rest
      in
        part.wrong ++ (
          if builtins.length part.right == 0
          then []
          else builtins.concatMap (x: requires (requireFile (builtins.dirOf file) x)) part.right
        );
in {
  # Helper for mach-nix requirements. It looks for includes of the form "-r filename.txt" and recursively
  # inlines them instead as mach-nix doesn't currently support this feature.
  requirements = file: builtins.concatStringsSep "\n" (requires file);
}
