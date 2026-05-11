module Tricorder.Arguments
    ( Command (..)
    , FollowMode (..)
    , OutputFormat (..)
    , StatusOptions (..)
    , TestOptions (..)
    , Verbosity (..)
    , WaitMode (..)
    , parseArguments
    , runArguments
    ) where

import Effectful (IOE)
import Effectful.Reader.Static (Reader, runReader)
import Options.Applicative
    ( Parser
    , ParserInfo
    , argument
    , auto
    , command
    , execParser
    , flag
    , fullDesc
    , header
    , help
    , helper
    , hsubparser
    , info
    , infoOption
    , long
    , metavar
    , option
    , progDesc
    , short
    , str
    )

import Tricorder.GhcPkg.Types (ModuleName (..))

import Tricorder.Version qualified as Version


data WaitMode
    = ShowCurrent
    | WaitForBuild
    deriving stock (Eq)


data OutputFormat
    = TextOutput
    | JsonOutput
    deriving stock (Eq)


data Verbosity
    = Concise
    | Verbose
    deriving stock (Eq)


data FollowMode
    = NoFollow
    | Follow
    deriving stock (Eq)


data StatusOptions = StatusOptions
    { wait :: WaitMode
    , format :: OutputFormat
    , verbosity :: Verbosity
    , expand :: Maybe Int
    }


data TestOptions = TestOptions
    { failedOnly :: Bool
    , wait :: WaitMode
    }


data Command
    = Start
    | Stop
    | Status StatusOptions
    | Test TestOptions
    | UI
    | Log FollowMode
    | Source [ModuleName]


runArguments :: (IOE :> es) => Eff (Reader Command : es) a -> Eff es a
runArguments eff = do
    args <- liftIO parseArguments
    runReader args eff


parseArguments :: IO Command
parseArguments = execParser opts


opts :: ParserInfo Command
opts =
    info (commandParser <**> versionOption <**> helper)
        $ fullDesc
            <> progDesc "tricorder — daemon-based GHCi build status"
            <> header "tricorder — robust GHCi daemon with structured querying"


versionOption :: Parser (a -> a)
versionOption = infoOption (toString Version.gitHash) (long "version" <> help "Show version and exit")


commandParser :: Parser Command
commandParser =
    hsubparser
        ( command "start" (info (pure Start) (progDesc "Start the daemon (no-op if already running)"))
            <> command "stop" (info (pure Stop) (progDesc "Stop the daemon"))
            <> command "status" (info statusParser (progDesc "Print build diagnostics (--json for machine-readable output)"))
            <> command "test-results" (info testParser (progDesc "Show output from the latest test run"))
            <> command "ui" (info (pure UI) (progDesc "Auto-refreshing terminal display"))
            <> command "log" (info logParser (progDesc "Show daemon log output"))
            <> command "source" (info sourceParser (progDesc "Print the Haskell source of one or more installed modules"))
        )


logParser :: Parser Command
logParser =
    Log
        <$> flag
            NoFollow
            Follow
            ( long "follow"
                <> short 'f'
                <> help "Keep streaming new log lines as they are written"
            )


statusParser :: Parser Command
statusParser =
    Status
        <$> ( StatusOptions
                <$> flag
                    ShowCurrent
                    WaitForBuild
                    ( long "wait"
                        <> help "Block until the current build cycle completes"
                    )
                <*> flag
                    TextOutput
                    JsonOutput
                    ( long "json"
                        <> help "Output full build state as JSON"
                    )
                <*> flag
                    Concise
                    Verbose
                    ( long "verbose"
                        <> short 'v'
                        <> help "Print full GHC message body under each diagnostic"
                    )
                <*> optional
                    ( option
                        auto
                        ( long "expand"
                            <> metavar "N"
                            <> help "Print full GHC message body for diagnostic #N"
                        )
                    )
            )


testParser :: Parser Command
testParser =
    Test
        <$> ( TestOptions
                <$> flag
                    False
                    True
                    ( long "failed"
                        <> help "Only show output from failed test suites"
                    )
                <*> flag
                    ShowCurrent
                    WaitForBuild
                    ( long "wait"
                        <> help "Block until the current build cycle completes"
                    )
            )


sourceParser :: Parser Command
sourceParser =
    Source
        <$> some (argument (fromString <$> str) (metavar "MODULE" <> help "Dotted module name, e.g. Data.Map.Strict"))
