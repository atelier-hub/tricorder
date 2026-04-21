module Tricorder.Arguments
    ( Command (..)
    , parseArguments
    , runArguments
    ) where

import Effectful (IOE)
import Effectful.Reader.Static (Reader, runReader)
import Options.Applicative
    ( Parser
    , ParserInfo
    , argument
    , command
    , execParser
    , fullDesc
    , header
    , help
    , helper
    , hsubparser
    , info
    , long
    , metavar
    , progDesc
    , short
    , str
    , switch
    )

import Tricorder.GhcPkg.Types (ModuleName (..))


data Command
    = Start
    | Stop
    | Status Bool Bool Bool
    | UI
    | Log Bool
    | Source [ModuleName]


runArguments :: (IOE :> es) => Eff (Reader Command : es) a -> Eff es a
runArguments eff = do
    args <- liftIO parseArguments
    runReader args eff


parseArguments :: IO Command
parseArguments = execParser opts


opts :: ParserInfo Command
opts =
    info (commandParser <**> helper)
        $ fullDesc
            <> progDesc "tricorder — daemon-based GHCi build status"
            <> header "tricorder — robust GHCi daemon with structured querying"


commandParser :: Parser Command
commandParser =
    hsubparser
        ( command "start" (info (pure Start) (progDesc "Start the daemon (no-op if already running)"))
            <> command "stop" (info (pure Stop) (progDesc "Stop the daemon"))
            <> command "status" (info statusParser (progDesc "Print build diagnostics (--json for machine-readable output)"))
            <> command "ui" (info (pure UI) (progDesc "Auto-refreshing terminal display"))
            <> command "log" (info logParser (progDesc "Show daemon log output"))
            <> command "source" (info sourceParser (progDesc "Print the Haskell source of one or more installed modules"))
        )


logParser :: Parser Command
logParser =
    Log
        <$> switch
            ( long "follow"
                <> short 'f'
                <> help "Keep streaming new log lines as they are written"
            )


statusParser :: Parser Command
statusParser =
    Status
        <$> switch
            ( long "wait"
                <> help "Block until the current build cycle completes"
            )
        <*> switch
            ( long "json"
                <> help "Output full build state as JSON"
            )
        <*> switch
            ( long "verbose"
                <> short 'v'
                <> help "Print full GHC message body under each diagnostic"
            )


sourceParser :: Parser Command
sourceParser =
    Source
        <$> some (argument (fromString <$> str) (metavar "MODULE" <> help "Dotted module name, e.g. Data.Map.Strict"))
