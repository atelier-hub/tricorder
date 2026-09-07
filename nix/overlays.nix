{
  inputs,
  project,
  shell,
}:
[
  inputs.haskell-nix.overlay
  (final: _prev: {
    tricorderProject = final.haskell-nix.hix.project (
      project
      // {
        # uncomment with your current system for `nix flake show` to work:
        # evalSystem = "x86_64-linux";
        inherit shell;
      }
    );
  })
]
