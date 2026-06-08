{
  author = "Christian Georgii";
  maintainer = "christian.georgii@tweag.io";
  license = "MIT";
  license-file = "LICENSE";
  language = "GHC2021";

  ghc-options = [
    "-Weverything"
    "-Wno-unsafe"
    "-Wno-missing-safe-haskell-mode"
    "-Wno-monomorphism-restriction"
    "-Wno-missing-kind-signatures"
    "-Wno-missing-poly-kind-signatures"
    "-Wno-missing-role-annotations"
    "-Wno-missing-local-signatures"
    "-Wno-missing-import-lists"
    "-Wno-implicit-prelude"
    "-Wno-unticked-promoted-constructors"
    "-Wno-unused-packages"
    # Missed-specialisation warnings fire on imported overloaded functions (e.g.
    # realToFrac, Data.Fixed instances, prometheus exporters) that we can't annotate
    # with INLINABLE. They only appear under optimization and aren't actionable.
    "-Wno-all-missed-specialisations"
    "-Wno-missed-specialisations"
    "-fplugin=Effectful.Plugin"
    "-threaded"
  ];
}
