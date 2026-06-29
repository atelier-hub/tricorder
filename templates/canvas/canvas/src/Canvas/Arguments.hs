-- | Command-line options for the @canvas@ executable, parsed through the
-- atelier 'Atelier.Effects.Arguments.Arguments' effect.
module Canvas.Arguments
    ( Options (..)
    , optionsInfo
    )
where

import Options.Applicative
    ( Parser
    , ParserInfo
    , fullDesc
    , header
    , help
    , helper
    , info
    , long
    , metavar
    , progDesc
    , short
    , showDefault
    , strOption
    , value
    )


-- | Parsed command-line options.
newtype Options = Options
    { configPath :: FilePath
    -- ^ Path to the YAML configuration file.
    }


-- | Top-level parser with @--help@ wired in.
optionsInfo :: ParserInfo Options
optionsInfo =
    info (optionsParser <**> helper)
        $ fullDesc
            <> progDesc "canvas — sample atelier service"
            <> header "canvas"


optionsParser :: Parser Options
optionsParser =
    Options
        <$> strOption
            ( long "config"
                <> short 'c'
                <> metavar "PATH"
                <> value "config/dev.yaml"
                <> showDefault
                <> help "Path to the YAML configuration file"
            )
