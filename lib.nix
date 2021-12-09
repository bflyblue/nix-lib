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

    # AWS Lambda Base Image for Custom Runtime
    awsLambdaProvided = pkgs.dockerTools.pullImage {
      imageName = "amazon/aws-lambda-provided";
      imageDigest = "sha256:1b8ab5631ed5bf9aebabf9a0c04ad757e364ed8695fc3746ec704f477c49a915";
      sha256 = "0i7vgpfcv7k9psjjbx0nkidkj19wk2pc7jvvqlw7h9ybgqh1h0lr";
      finalImageName = "amazon/aws-lambda-provided";
      finalImageTag = "al2";
    };

    # LD_LIBRARY_PATH breaks nix binaries so this wrapper unsets it
    unsetLdLibraryPath = name: program: pkgs.writeScript name ''
      #!/bin/sh
      unset LD_LIBRARY_PATH
      exec ${program} "$@"
    ''; 

in {
  # Helper for mach-nix requirements. It looks for includes of the form "-r filename.txt" and recursively
  # inlines them instead as mach-nix doesn't currently support this feature.
  requirements = file: builtins.concatStringsSep "\n" (requires file);

  # Build a custom AWS Lambda docker container.
  buildLambdaImage = { name, contents, bootstrap }:
    pkgs.dockerTools.buildImage {
      inherit name contents;
      fromImage = awsLambdaProvided;
      runAsRoot = ''
        ${pkgs.runtimeShell}
        ln -s /usr/bin/sh /bin/sh
        cp ${unsetLdLibraryPath "bootstrap" bootstrap} /var/runtime/bootstrap
      '';
      config = {
        EntryPoint = [ "/lambda-entrypoint.sh" ];
        WorkingDir = "/var/task";
        Cmd = [ "handler" ];
      };
    };
}