{ system
  , compiler
  , flags
  , pkgs
  , hsPkgs
  , pkgconfPkgs
  , errorHandler
  , config
  , ... }:
  ({
    flags = { demos = false; };
    package = {
      specVersion = "1.18";
      identifier = { name = "brick"; version = "2.10"; };
      license = "BSD-3-Clause";
      copyright = "(c) Jonathan Daugherty 2015-2025";
      maintainer = "Jonathan Daugherty <cygnus@foobox.com>";
      author = "Jonathan Daugherty <cygnus@foobox.com>";
      homepage = "https://github.com/jtdaugherty/brick/";
      url = "";
      synopsis = "A declarative terminal user interface library";
      description = "Write terminal user interfaces (TUIs) painlessly with 'brick'! You\nwrite an event handler and a drawing function and the library does the\nrest.\n\n\n> module Main where\n>\n> import Brick\n>\n> ui :: Widget ()\n> ui = str \"Hello, world!\"\n>\n> main :: IO ()\n> main = simpleMain ui\n\n\nTo get started, see:\n\n* <https://github.com/jtdaugherty/brick/blob/master/README.md The README>\n\n* The <https://github.com/jtdaugherty/brick/blob/master/docs/guide.rst Brick user guide>\n\n* The demonstration programs in the 'programs' directory\n\n\nThis package deprecates <http://hackage.haskell.org/package/vty-ui vty-ui>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
          (hsPkgs."vty-crossplatform" or (errorHandler.buildDepError "vty-crossplatform"))
          (hsPkgs."bimap" or (errorHandler.buildDepError "bimap"))
          (hsPkgs."data-clist" or (errorHandler.buildDepError "data-clist"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
          (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
          (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."config-ini" or (errorHandler.buildDepError "config-ini"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."text-zipper" or (errorHandler.buildDepError "text-zipper"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."unix-compat" or (errorHandler.buildDepError "unix-compat"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."word-wrap" or (errorHandler.buildDepError "word-wrap"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
        ];
        buildable = true;
      };
      exes = {
        "brick-custom-keybinding-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
            (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
            (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-table-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-tail-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
            (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-readme-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-file-browser-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-form-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
            (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
            (hsPkgs."vty-crossplatform" or (errorHandler.buildDepError "vty-crossplatform"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-text-wrap-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."word-wrap" or (errorHandler.buildDepError "word-wrap"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-cache-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-visibility-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
            (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
            (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-viewport-scrollbars-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."vty-crossplatform" or (errorHandler.buildDepError "vty-crossplatform"))
            (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
            (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-viewport-scroll-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-dialog-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-mouse-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
            (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
            (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-layer-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
            (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
            (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-suspend-resume-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
            (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-cropping-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-padding-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-theme-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-attr-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-tabular-list-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
            (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
            (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-list-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
            (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-list-vi-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
            (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-animation-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."vty-crossplatform" or (errorHandler.buildDepError "vty-crossplatform"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."microlens-platform" or (errorHandler.buildDepError "microlens-platform"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-custom-event-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
            (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
            (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-fill-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-hello-world-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-edit-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
            (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
            (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-editor-line-numbers-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
            (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
            (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-border-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-dynamic-border-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
          ];
          buildable = if !flags.demos then false else true;
        };
        "brick-progressbar-demo" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
            (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
          ];
          buildable = if !flags.demos then false else true;
        };
      };
      tests = {
        "brick-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."vty-crossplatform" or (errorHandler.buildDepError "vty-crossplatform"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/brick-2.10.tar.gz";
      sha256 = "b8429fc8a6115aa1504e3ce1e3b5d14aec31dc38cb327f2d6deb2403b8c87e21";
    });
  }) // {
    package-description-override = "name:                brick\r\nversion:             2.10\r\nx-revision: 1\r\nsynopsis:            A declarative terminal user interface library\r\ndescription:\r\n  Write terminal user interfaces (TUIs) painlessly with 'brick'! You\r\n  write an event handler and a drawing function and the library does the\r\n  rest.\r\n  .\r\n  .\r\n  > module Main where\r\n  >\r\n  > import Brick\r\n  >\r\n  > ui :: Widget ()\r\n  > ui = str \"Hello, world!\"\r\n  >\r\n  > main :: IO ()\r\n  > main = simpleMain ui\r\n  .\r\n  .\r\n  To get started, see:\r\n  .\r\n  * <https://github.com/jtdaugherty/brick/blob/master/README.md The README>\r\n  .\r\n  * The <https://github.com/jtdaugherty/brick/blob/master/docs/guide.rst Brick user guide>\r\n  .\r\n  * The demonstration programs in the 'programs' directory\r\n  .\r\n  .\r\n  This package deprecates <http://hackage.haskell.org/package/vty-ui vty-ui>.\r\nlicense:             BSD3\r\nlicense-file:        LICENSE\r\nauthor:              Jonathan Daugherty <cygnus@foobox.com>\r\nmaintainer:          Jonathan Daugherty <cygnus@foobox.com>\r\ncopyright:           (c) Jonathan Daugherty 2015-2025\r\ncategory:            Graphics\r\nbuild-type:          Simple\r\ncabal-version:       1.18\r\nHomepage:            https://github.com/jtdaugherty/brick/\r\nBug-reports:         https://github.com/jtdaugherty/brick/issues\r\ntested-with:         GHC == 8.2.2\r\n                      || == 8.4.4\r\n                      || == 8.6.5\r\n                      || == 8.8.4\r\n                      || == 8.10.7\r\n                      || == 9.0.2\r\n                      || == 9.2.8\r\n                      || == 9.4.8\r\n                      || == 9.6.7\r\n                      || == 9.8.4\r\n                      || == 9.10.3\r\n                      || == 9.12.2\r\n\r\nextra-doc-files:     README.md,\r\n                     docs/guide.rst,\r\n                     docs/snake-demo.gif,\r\n                     CHANGELOG.md,\r\n                     programs/custom_keys.ini\r\n\r\nSource-Repository head\r\n  type:     git\r\n  location: http://github.com/jtdaugherty/brick\r\n\r\nFlag demos\r\n    Description:     Build demonstration programs\r\n    Default:         False\r\n\r\nlibrary\r\n  default-language:    Haskell2010\r\n  ghc-options:         -Wall -Wcompat -O2 -Wunused-packages\r\n  default-extensions:  CPP\r\n  hs-source-dirs:      src\r\n  exposed-modules:\r\n    Brick\r\n    Brick.Animation\r\n    Brick.AttrMap\r\n    Brick.BChan\r\n    Brick.BorderMap\r\n    Brick.Keybindings\r\n    Brick.Keybindings.KeyConfig\r\n    Brick.Keybindings.KeyEvents\r\n    Brick.Keybindings.KeyDispatcher\r\n    Brick.Keybindings.Normalize\r\n    Brick.Keybindings.Parse\r\n    Brick.Keybindings.Pretty\r\n    Brick.Focus\r\n    Brick.Forms\r\n    Brick.Main\r\n    Brick.Themes\r\n    Brick.Types\r\n    Brick.Util\r\n    Brick.Widgets.Border\r\n    Brick.Widgets.Border.Style\r\n    Brick.Widgets.Center\r\n    Brick.Widgets.Core\r\n    Brick.Widgets.Dialog\r\n    Brick.Widgets.Edit\r\n    Brick.Widgets.FileBrowser\r\n    Brick.Widgets.List\r\n    Brick.Widgets.ProgressBar\r\n    Brick.Widgets.Table\r\n    Data.IMap\r\n  other-modules:\r\n    Brick.Animation.Clock\r\n    Brick.Types.Common\r\n    Brick.Types.TH\r\n    Brick.Types.EventM\r\n    Brick.Types.Internal\r\n    Brick.Widgets.Internal\r\n\r\n  build-depends:       base >= 4.9.0.0 && < 4.23,\r\n                       vty >= 6.0,\r\n                       vty-crossplatform,\r\n                       bimap >= 0.5 && < 0.6,\r\n                       data-clist >= 0.1,\r\n                       directory >= 1.2.5.0,\r\n                       exceptions >= 0.10.0,\r\n                       filepath,\r\n                       containers >= 0.5.7,\r\n                       microlens >= 0.3.0.0,\r\n                       microlens-th,\r\n                       microlens-mtl,\r\n                       mtl,\r\n                       config-ini,\r\n                       vector,\r\n                       stm >= 2.4.3,\r\n                       text,\r\n                       text-zipper >= 0.13,\r\n                       template-haskell,\r\n                       deepseq >= 1.3 && < 1.6,\r\n                       unix-compat,\r\n                       bytestring,\r\n                       word-wrap >= 0.2,\r\n                       unordered-containers,\r\n                       hashable,\r\n                       time\r\n\r\nexecutable brick-custom-keybinding-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  default-extensions:  CPP\r\n  main-is:             CustomKeybindingDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       text,\r\n                       vty,\r\n                       containers,\r\n                       microlens,\r\n                       microlens-mtl,\r\n                       microlens-th\r\n\r\nexecutable brick-table-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  default-extensions:  CPP\r\n  main-is:             TableDemo.hs\r\n  build-depends:       base,\r\n                       brick\r\n\r\nexecutable brick-tail-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  default-extensions:  CPP\r\n  main-is:             TailDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       text,\r\n                       vty,\r\n                       random,\r\n                       microlens-th,\r\n                       microlens-mtl\r\n\r\nexecutable brick-readme-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  default-extensions:  CPP\r\n  main-is:             ReadmeDemo.hs\r\n  build-depends:       base,\r\n                       brick\r\n\r\nexecutable brick-file-browser-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  default-extensions:  CPP\r\n  main-is:             FileBrowserDemo.hs\r\n  build-depends:       base,\r\n                       vty,\r\n                       brick,\r\n                       text,\r\n                       mtl\r\n\r\nexecutable brick-form-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  default-extensions:  CPP\r\n  main-is:             FormDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       text,\r\n                       microlens,\r\n                       microlens-th,\r\n                       vty-crossplatform,\r\n                       vty\r\n\r\nexecutable brick-text-wrap-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  default-extensions:  CPP\r\n  main-is:             TextWrapDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       word-wrap\r\n\r\nexecutable brick-cache-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  default-extensions:  CPP\r\n  main-is:             CacheDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       mtl\r\n\r\nexecutable brick-visibility-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             VisibilityDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       microlens >= 0.3.0.0,\r\n                       microlens-th,\r\n                       microlens-mtl\r\n\r\nexecutable brick-viewport-scrollbars-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  default-extensions:  CPP\r\n  main-is:             ViewportScrollbarsDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       vty-crossplatform,\r\n                       microlens-mtl,\r\n                       microlens-th\r\n\r\nexecutable brick-viewport-scroll-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  default-extensions:  CPP\r\n  main-is:             ViewportScrollDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty\r\n\r\nexecutable brick-dialog-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             DialogDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty\r\n\r\nexecutable brick-mouse-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             MouseDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       microlens >= 0.3.0.0,\r\n                       microlens-th,\r\n                       microlens-mtl,\r\n                       mtl\r\n\r\nexecutable brick-layer-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             LayerDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       microlens >= 0.3.0.0,\r\n                       microlens-th,\r\n                       microlens-mtl\r\n\r\nexecutable brick-suspend-resume-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             SuspendAndResumeDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       microlens >= 0.3.0.0,\r\n                       microlens-th\r\n\r\nexecutable brick-cropping-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             CroppingDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty\r\n\r\nexecutable brick-padding-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             PaddingDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty\r\n\r\nexecutable brick-theme-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             ThemeDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       mtl\r\n\r\nexecutable brick-attr-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             AttrDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty\r\n\r\nexecutable brick-tabular-list-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             TabularListDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       microlens >= 0.3.0.0,\r\n                       microlens-mtl,\r\n                       microlens-th,\r\n                       vector\r\n\r\nexecutable brick-list-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             ListDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       microlens >= 0.3.0.0,\r\n                       microlens-mtl,\r\n                       mtl,\r\n                       vector\r\n\r\nexecutable brick-list-vi-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             ListViDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       microlens >= 0.3.0.0,\r\n                       microlens-mtl,\r\n                       mtl,\r\n                       vector\r\n\r\nexecutable brick-animation-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             AnimationDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       vty-crossplatform,\r\n                       containers,\r\n                       microlens-platform\r\n\r\nexecutable brick-custom-event-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             CustomEventDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       microlens >= 0.3.0.0,\r\n                       microlens-th,\r\n                       microlens-mtl\r\n\r\nexecutable brick-fill-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             FillDemo.hs\r\n  build-depends:       base,\r\n                       brick\r\n\r\nexecutable brick-hello-world-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             HelloWorldDemo.hs\r\n  build-depends:       base,\r\n                       brick\r\n\r\nexecutable brick-edit-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             EditDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       microlens >= 0.3.0.0,\r\n                       microlens-th,\r\n                       microlens-mtl\r\n\r\nexecutable brick-editor-line-numbers-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-language:    Haskell2010\r\n  main-is:             EditorLineNumbersDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       microlens >= 0.3.0.0,\r\n                       microlens-th,\r\n                       microlens-mtl\r\n\r\nexecutable brick-border-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-extensions:  CPP\r\n  default-language:    Haskell2010\r\n  main-is:             BorderDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       text\r\n\r\nexecutable brick-dynamic-border-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-extensions:  CPP\r\n  default-language:    Haskell2010\r\n  main-is:             DynamicBorderDemo.hs\r\n  build-depends:       base <= 5,\r\n                       brick\r\n\r\nexecutable brick-progressbar-demo\r\n  if !flag(demos)\r\n    Buildable: False\r\n  hs-source-dirs:      programs\r\n  ghc-options:         -threaded -Wall -Wcompat -O2\r\n  default-extensions:  CPP\r\n  default-language:    Haskell2010\r\n  main-is:             ProgressBarDemo.hs\r\n  build-depends:       base,\r\n                       brick,\r\n                       vty,\r\n                       microlens-mtl,\r\n                       microlens-th\r\n\r\ntest-suite brick-tests\r\n  type:                exitcode-stdio-1.0\r\n  hs-source-dirs:      tests\r\n  ghc-options:         -Wall -Wcompat -Wno-orphans -O2\r\n  default-language:    Haskell2010\r\n  main-is:             Main.hs\r\n  other-modules:       List Render\r\n  build-depends:       base <=5,\r\n                       brick,\r\n                       containers,\r\n                       microlens,\r\n                       vector,\r\n                       vty,\r\n                       vty-crossplatform,\r\n                       QuickCheck\r\n";
  }