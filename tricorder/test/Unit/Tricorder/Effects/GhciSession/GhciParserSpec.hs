module Unit.Tricorder.Effects.GhciSession.GhciParserSpec (spec_GhciParser) where

import Test.Hspec

import Tricorder.Effects.GhciSession.GhciParser
    ( GhciLoad (..)
    , GhciLoading (..)
    , GhciMessage (..)
    , GhciSeverity (..)
    , Position (..)
    , parseReload
    , parseShowModules
    )


spec_GhciParser :: Spec
spec_GhciParser = do
    describe "parseReload" do
        describe "clean build" testCleanBuild
        describe "with errors and warnings" testErrors
        describe "with -fhide-source-paths (no Loading items)" testHideSourcePaths
        describe "with <no location info> errors" testNoLocationInfo
        describe "with Loaded GHCi configuration" testLoadedConfig

    describe "parseShowModules" do
        describe "typical output" testShowModules
        describe "empty / blank input" testShowModulesEmpty


--------------------------------------------------------------------------------
-- parseReload: clean build
--------------------------------------------------------------------------------

testCleanBuild :: Spec
testCleanBuild = do
    it "produces GLoading items for each compiled module" do
        let input =
                [ "[1 of 3] Compiling Tricorder.BuildState ( src/Tricorder/BuildState.hs, interpreted )"
                , "[2 of 3] Compiling Tricorder.Session    ( src/Tricorder/Session.hs, interpreted )"
                , "[3 of 3] Compiling Main                 ( app/Main.hs, interpreted )"
                , "Ok, 3 modules loaded."
                ]
        parseReload input
            `shouldBe` [ GLoading GhciLoading {index = 1, total = 3, moduleName = "Tricorder.BuildState", sourceFile = "src/Tricorder/BuildState.hs"}
                       , GLoading GhciLoading {index = 2, total = 3, moduleName = "Tricorder.Session", sourceFile = "src/Tricorder/Session.hs"}
                       , GLoading GhciLoading {index = 3, total = 3, moduleName = "Main", sourceFile = "app/Main.hs"}
                       ]

    it "handles padded module index (e.g. [ 1 of 47])" do
        let input =
                [ "[ 1 of 47] Compiling Main              ( app/Main.hs, interpreted )"
                , "Ok, 1 module loaded."
                ]
        parseReload input `shouldBe` [GLoading GhciLoading {index = 1, total = 47, moduleName = "Main", sourceFile = "app/Main.hs"}]

    describe "when only summary line" $ it "returns empty list" do
        parseReload ["Ok, 0 modules loaded."] `shouldBe` []


--------------------------------------------------------------------------------
-- parseReload: errors and warnings
--------------------------------------------------------------------------------

testErrors :: Spec
testErrors = do
    it "parses a single-line error" do
        let input = ["src/Foo.hs:10:5: error: Variable not in scope: foo"]
        parseReload input
            `shouldBe` [GMessage GhciMessage {severity = GError, file = "src/Foo.hs", startPos = Position 10 5, endPos = Position 10 5, messageLines = ["src/Foo.hs:10:5: error: Variable not in scope: foo"]}]

    it "parses a warning with continuation lines" do
        let input =
                [ "src/Bar.hs:20:3: warning: [-Wunused-imports]"
                , "    Redundant import: Data.List"
                , "    Perhaps you want to remove it."
                ]
        parseReload input
            `shouldBe` [ GMessage
                            GhciMessage
                                { severity = GWarning
                                , file = "src/Bar.hs"
                                , startPos = Position 20 3
                                , endPos = Position 20 3
                                , messageLines =
                                    [ "src/Bar.hs:20:3: warning: [-Wunused-imports]"
                                    , "    Redundant import: Data.List"
                                    , "    Perhaps you want to remove it."
                                    ]
                                }
                       ]

    it "parses a span position (L:C-C2:)" do
        let input = ["src/Baz.hs:5:1-10: error: Parse error"]
        parseReload input
            `shouldBe` [GMessage GhciMessage {severity = GError, file = "src/Baz.hs", startPos = Position 5 1, endPos = Position 5 10, messageLines = ["src/Baz.hs:5:1-10: error: Parse error"]}]

    it "parses a span position ((L1,C1)-(L2,C2):)" do
        let input = ["src/Qux.hs:(3,1)-(5,20): error: Multi-line error"]
        parseReload input
            `shouldBe` [GMessage GhciMessage {severity = GError, file = "src/Qux.hs", startPos = Position 3 1, endPos = Position 5 20, messageLines = ["src/Qux.hs:(3,1)-(5,20): error: Multi-line error"]}]

    it "parses a span position with double-paren end ((L1,C1)-((L2,C2):)" do
        let input = ["src/Qux.hs:(3,1)-((5,20): error: Multi-line error"]
        parseReload input
            `shouldBe` [GMessage GhciMessage {severity = GError, file = "src/Qux.hs", startPos = Position 3 1, endPos = Position 5 20, messageLines = ["src/Qux.hs:(3,1)-((5,20): error: Multi-line error"]}]

    it "parses source-display continuation lines (pipe format)" do
        let input =
                [ "src/Foo.hs:10:5: error: Variable not in scope: foo"
                , "   |"
                , "10 | foo bar"
                , "   | ^^^"
                , "    Suggested fix: import Foo"
                ]
        parseReload input
            `shouldBe` [ GMessage
                            GhciMessage
                                { severity = GError
                                , file = "src/Foo.hs"
                                , startPos = Position 10 5
                                , endPos = Position 10 5
                                , messageLines =
                                    [ "src/Foo.hs:10:5: error: Variable not in scope: foo"
                                    , "   |"
                                    , "10 | foo bar"
                                    , "   | ^^^"
                                    , "    Suggested fix: import Foo"
                                    ]
                                }
                       ]

    it "strips ANSI codes from header for matching but stores original in glMessage" do
        let ansiHeader = "\ESC[1msrc/Foo.hs:10:5:\ESC[0m \ESC[91merror:\ESC[0m Variable not in scope: foo"
        parseReload [ansiHeader]
            `shouldBe` [GMessage GhciMessage {severity = GError, file = "src/Foo.hs", startPos = Position 10 5, endPos = Position 10 5, messageLines = [ansiHeader]}]

    it "parses a Windows drive-letter path in a diagnostic" do
        let input = ["C:\\path\\file.hs:10:5: error: Variable not in scope: foo"]
        parseReload input
            `shouldBe` [GMessage GhciMessage {severity = GError, file = "C:\\path\\file.hs", startPos = Position 10 5, endPos = Position 10 5, messageLines = ["C:\\path\\file.hs:10:5: error: Variable not in scope: foo"]}]

    it "parses mixed Loading and Message items, discarding summary" do
        let input =
                [ "[1 of 2] Compiling Lib ( src/Lib.hs, interpreted )"
                , "src/Lib.hs:5:1: error: Oops"
                , "[2 of 2] Compiling Main ( app/Main.hs, interpreted )"
                , "Failed, 1 module loaded."
                ]
        parseReload input
            `shouldBe` [ GLoading GhciLoading {index = 1, total = 2, moduleName = "Lib", sourceFile = "src/Lib.hs"}
                       , GMessage GhciMessage {severity = GError, file = "src/Lib.hs", startPos = Position 5 1, endPos = Position 5 1, messageLines = ["src/Lib.hs:5:1: error: Oops"]}
                       , GLoading GhciLoading {index = 2, total = 2, moduleName = "Main", sourceFile = "app/Main.hs"}
                       ]


--------------------------------------------------------------------------------
-- parseReload: -fhide-source-paths output
--------------------------------------------------------------------------------

testHideSourcePaths :: Spec
testHideSourcePaths = do
    describe "when source paths are hidden" $ it "produces no GLoading items" do
        let input =
                [ "src/Foo.hs:10:5: error: Variable not in scope: foo"
                , "    Perhaps you meant: 'bar'"
                , "Failed, one module failed to load."
                ]
        parseReload input
            `shouldBe` [ GMessage
                            GhciMessage
                                { severity = GError
                                , file = "src/Foo.hs"
                                , startPos = Position 10 5
                                , endPos = Position 10 5
                                , messageLines =
                                    [ "src/Foo.hs:10:5: error: Variable not in scope: foo"
                                    , "    Perhaps you meant: 'bar'"
                                    ]
                                }
                       ]

    describe "when all modules are already up to date" $ it "returns empty list" do
        -- GHCi with -fhide-source-paths and nothing to recompile
        parseReload ["Ok, 5 modules loaded."] `shouldBe` []


--------------------------------------------------------------------------------
-- parseReload: <no location info> errors
--------------------------------------------------------------------------------

testNoLocationInfo :: Spec
testNoLocationInfo = do
    it "handles <no location info>: error: with continuation" do
        let input =
                [ "<no location info>: error:"
                , "    Module `Tricorder.Missing' is not loaded."
                ]
        parseReload input
            `shouldBe` [ GMessage
                            GhciMessage
                                { severity = GError
                                , file = "<no location info>"
                                , startPos = Position 0 0
                                , endPos = Position 0 0
                                , messageLines =
                                    [ "<no location info>: error:"
                                    , "    Module `Tricorder.Missing' is not loaded."
                                    ]
                                }
                       ]

    it "handles <no location info>: error: with no continuation" do
        parseReload ["<no location info>: error: some error"]
            `shouldBe` [GMessage GhciMessage {severity = GError, file = "<no location info>", startPos = Position 0 0, endPos = Position 0 0, messageLines = ["<no location info>: error: some error"]}]


--------------------------------------------------------------------------------
-- parseReload: Loaded GHCi configuration
--------------------------------------------------------------------------------

testLoadedConfig :: Spec
testLoadedConfig = do
    it "parses a GHCi configuration line" do
        parseReload ["Loaded GHCi configuration from /home/user/project/.ghci"]
            `shouldBe` [GLoadConfig "/home/user/project/.ghci"]

    it "parses a Windows-style GHCi configuration path" do
        parseReload ["Loaded GHCi configuration from C:\\Users\\user\\project\\.ghci"]
            `shouldBe` [GLoadConfig "C:\\Users\\user\\project\\.ghci"]

    it "handles config line mixed with other output" do
        let input =
                [ "Loaded GHCi configuration from .ghci"
                , "[1 of 1] Compiling Main ( app/Main.hs, interpreted )"
                , "Ok, 1 module loaded."
                ]
        parseReload input
            `shouldBe` [ GLoadConfig ".ghci"
                       , GLoading GhciLoading {index = 1, total = 1, moduleName = "Main", sourceFile = "app/Main.hs"}
                       ]


--------------------------------------------------------------------------------
-- parseShowModules
--------------------------------------------------------------------------------

testShowModules :: Spec
testShowModules = do
    it "parses typical :show modules output" do
        let input =
                [ "Tricorder.BuildState     ( src/Tricorder/BuildState.hs, interpreted )"
                , "Tricorder.Session        ( src/Tricorder/Session.hs, interpreted )"
                , "Main                     ( app/Main.hs, interpreted )"
                ]
        parseShowModules input
            `shouldBe` [ ("Tricorder.BuildState", "src/Tricorder/BuildState.hs")
                       , ("Tricorder.Session", "src/Tricorder/Session.hs")
                       , ("Main", "app/Main.hs")
                       ]

    it "parses absolute paths" do
        parseShowModules ["Lib ( /home/user/project/src/Lib.hs, interpreted )"]
            `shouldBe` [("Lib", "/home/user/project/src/Lib.hs")]

    it "strips ANSI codes before parsing" do
        parseShowModules ["\ESC[1mMain\ESC[0m                     ( app/Main.hs, interpreted )"]
            `shouldBe` [("Main", "app/Main.hs")]


testShowModulesEmpty :: Spec
testShowModulesEmpty = do
    it "returns empty list for empty input" do
        parseShowModules [] `shouldBe` []

    it "returns empty list for blank lines" do
        parseShowModules ["", "   ", "\t"] `shouldBe` []

    it "skips lines without '( '" do
        parseShowModules ["just some random text"] `shouldBe` []
