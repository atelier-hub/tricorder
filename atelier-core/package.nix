let
  deps = import ../hpack/dependencies.nix;
  inherit (deps) depList constraints;
in
{
  name = "atelier-core";
  version = "0.1.0.0";
  synopsis = "Foundational Effectful-based effects and utilities";
  description = "Core effects and utilities for effect-based applications, built on Effectful — part of the atelier toolkit.";
  author = "Christian Georgii";
  maintainer = "christian.georgii@tweag.io";
  license = "MIT";
  license-file = "LICENSE";
  github = "atelier-hub/tricorder";
  category = "Control";

  extra-doc-files = [
    "CHANGELOG.md"
    "README.md"
  ];

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

  dependencies = [
    constraints.effectful-core
    constraints.effectful-plugin
  ];

  default-extensions = [
    "BlockArguments"
    "DataKinds"
    "DeriveAnyClass"
    "DerivingStrategies"
    "DerivingVia"
    "DuplicateRecordFields"
    "FlexibleContexts"
    "GADTs"
    "LambdaCase"
    "MultiWayIf"
    "OverloadedLabels"
    "OverloadedRecordDot"
    "OverloadedStrings"
    "StrictData"
    "TemplateHaskell"
    "TypeFamilies"
  ];

  library = {
    source-dirs = "src";
    dependencies = [
      {
        name = "base";
        version = constraints.base;
        mixin = [
          "hiding (Prelude)"
        ];
      }
    ]
    ++ depList [
      "atelier-prelude"
      "aeson"
      "base64-bytestring"
      "bytestring"
      "casing"
      "containers"
      "contra-tracer"
      "daemons"
      "data-default"
      "directory"
      "effectful"
      "effectful-th"
      "filepath"
      "fsnotify"
      "hs-opentelemetry-api"
      "hs-opentelemetry-exporter-otlp"
      "hs-opentelemetry-sdk"
      "http-api-data"
      "http-types"
      "ki"
      "list-t"
      "optparse-applicative"
      "process"
      "prometheus-client"
      "prometheus-metrics-ghc"
      "stm"
      "stm-containers"
      "text"
      "time"
      "time-units"
      "typed-process"
      "unagi-chan"
      "unix"
      "unordered-containers"
      "uuid"
      "wai"
      "warp"
    ];
  };

  tests = {
    atelier-test = {
      main = "Driver.hs";
      source-dirs = "test";
      ghc-options = [ "-Wno-prepositive-qualified-module" ];
      build-tools = [ "tasty-discover:tasty-discover" ];
      dependencies = [
        {
          name = "base";
          version = constraints.base;
          mixin = [
            "hiding (Prelude)"
          ];
        }
      ]
      ++ depList [
        "atelier-prelude"
        "atelier-core"
        "aeson"
        "async"
        "bytestring"
        "containers"
        "data-default"
        "effectful"
        "hedgehog"
        "hs-opentelemetry-api"
        "hspec"
        "hspec-hedgehog"
        "stm"
        "stm-containers"
        "tasty"
        "tasty-hspec"
        "time"
      ];
    };
  };
}
