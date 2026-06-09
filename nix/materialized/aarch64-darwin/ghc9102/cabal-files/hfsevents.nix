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
    flags = {};
    package = {
      specVersion = "2.2";
      identifier = { name = "hfsevents"; version = "0.1.8"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "stegeman@gmail.com";
      author = "Luite Stegeman";
      homepage = "http://github.com/luite/hfsevents";
      url = "";
      synopsis = "File/folder watching for OS X";
      description = "";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."cereal" or (errorHandler.buildDepError "cereal"))
          (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        libs = [ (pkgs."pthread" or (errorHandler.sysDepError "pthread")) ];
        frameworks = [ (pkgs."Cocoa" or (errorHandler.sysDepError "Cocoa")) ];
        buildable = if system.isOsx then true else false;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hfsevents-0.1.8.tar.gz";
      sha256 = "c4e410ee68bf40bb9ebe6595f903fe6bac9d6f58106f153141161591306c6f7b";
    });
  }) // {
    package-description-override = "cabal-version:       2.2\nname:                hfsevents\nversion:             0.1.8\nsynopsis:            File/folder watching for OS X\nhomepage:            http://github.com/luite/hfsevents\nlicense:             BSD-3-Clause\nlicense-file:        LICENSE\nauthor:              Luite Stegeman\nmaintainer:          stegeman@gmail.com\ncategory:            System\nbuild-type:          Simple\nextra-source-files:  cbits/c_fsevents.h, test/test.hs, test/trace.hs\n\nsource-repository head\n  type:     git\n  location: https://github.com/luite/hfsevents.git\n\nlibrary\n  default-language: Haskell98\n  exposed-modules: System.OSX.FSEvents\n  if os(darwin)\n    buildable: True\n  else\n    buildable: False\n  frameworks: Cocoa\n  cxx-sources: cbits/c_fsevents.m\n  include-dirs: cbits\n  extra-libraries: pthread\n  build-depends:\n    base >= 4 && < 5,\n    bytestring,\n    cereal >= 0.3 && < 0.6,\n    unix,\n    mtl,\n    text\n\n";
  }