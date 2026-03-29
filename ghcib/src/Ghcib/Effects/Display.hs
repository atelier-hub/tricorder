module Ghcib.Effects.Display
    ( -- * Style
      Style (..)

      -- * Effect
    , Display
    , putDoc
    , putDocLn
    , resetScreen

      -- * Interpreters
    , runDisplayIO
    , runDisplayNoOp
    , runDisplayCapture
    ) where

import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.State.Static.Local (State, modify)
import Effectful.TH (makeEffect)
import Prettyprinter (Doc, defaultLayoutOptions, hardline, layoutPretty, reAnnotate, unAnnotate)
import Prettyprinter.Render.Terminal (AnsiStyle, Color (..), bold, color, renderIO)
import Prettyprinter.Render.Text (renderStrict)
import System.Console.ANSI (clearScreen, setCursorPosition)


-- | Semantic display styles, independent of any rendering backend.
data Style
    = -- | Rendered as red
      Err
    | -- | Rendered as yellow
      Warn
    | -- | Rendered as green
      Ok
    | -- | Rendered as bold
      Emphasis


styleToAnsi :: Style -> AnsiStyle
styleToAnsi = \case
    Err -> color Red
    Warn -> color Yellow
    Ok -> color Green
    Emphasis -> bold


data Display :: Effect where
    -- | Render a document to stdout.
    PutDoc :: Doc Style -> Display m ()
    -- | Clear the screen and reset the cursor to the top-left.
    ResetScreen :: Display m ()


makeEffect ''Display


-- | Like 'putDoc' but appends a newline.
putDocLn :: (Display :> es) => Doc Style -> Eff es ()
putDocLn doc = putDoc (doc <> hardline)


-- | Production interpreter: renders to the terminal with ANSI color codes.
runDisplayIO :: (IOE :> es) => Eff (Display : es) a -> Eff es a
runDisplayIO = interpret_ \case
    PutDoc doc ->
        liftIO $ renderIO stdout (layoutPretty defaultLayoutOptions (reAnnotate styleToAnsi doc))
    ResetScreen -> liftIO $ clearScreen >> setCursorPosition 0 0


-- | No-op interpreter: discards all output. Useful for tests.
runDisplayNoOp :: Eff (Display : es) a -> Eff es a
runDisplayNoOp = interpret_ \case
    PutDoc _ -> pure ()
    ResetScreen -> pure ()


-- | Capturing interpreter: renders each 'putDoc' call to plain text (no ANSI
-- codes) and appends it to a 'State' list. Useful for end-to-end tests.
--
-- @
-- texts \<- execState \@[Text] [] $ runDisplayCapture $ renderState bs
-- @
runDisplayCapture :: (State [Text] :> es) => Eff (Display : es) a -> Eff es a
runDisplayCapture = interpret_ \case
    PutDoc doc -> modify (<> [renderStrict (layoutPretty defaultLayoutOptions (unAnnotate doc))])
    ResetScreen -> pure ()
