# tmp-postgres isn't on Hackage, so every cabalProject that touches atelier-db's
# test suite must pull it from the flake input. This is the single source of
# truth for that `source-repository-package` stanza, shared by nix/project.nix
# and nix/template-checks.nix.
#
# (The standalone canvas template carries its own copy in
# templates/canvas/nix/project.nix — it's a separate flake and can't import
# this one.)
{ inputs }:
''
  source-repository-package
    type: git
    location: https://github.com/jfischoff/tmp-postgres
    tag: ${inputs.tmp-postgres.rev}
    --sha256: 0l1gdx5s8ximgawd3yzfy47pv5pgwqmjqp8hx5rbrq68vr04wkbl
''
