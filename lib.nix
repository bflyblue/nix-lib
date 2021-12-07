{ pkgs, lib }:

let lines = file: lib.splitString "\n" (builtins.readFile file);
    isRequire = lib.hasPrefix "-r ";
    requireFile = dir: file: "${dir}/${lib.removePrefix "-r " file}";
    requires = file:
      let part = lib.partition isRequire (lines file);
      in
        if builtins.length part.right == 0 then
          part.wrong
        else
          part.wrong ++ builtins.concatMap (x: requires (requireFile (builtins.dirOf file) x)) part.right;
    requirements = file: builtins.concatStringsSep "\n" (requires file);
in {
  inherit requirements;
}
