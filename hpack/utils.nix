let
  constraints = import ./constraints.nix;
in
{
  dep = map (name: "${name} ${constraints.${name}}");
}
