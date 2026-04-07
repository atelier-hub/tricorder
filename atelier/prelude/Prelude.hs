-- | This Prelude is meant to mimic the `relude` package's `Relude` module,
-- with the following exceptions:
--
-- - No MTL classes or monads.
-- - No functions for manipulating IORefs, MVars and STM-based vars.
module Prelude
    ( -- * Reexports from Effectful
      module Effectful

      -- * Reexports from Relude.Monad
    , module Control.Monad
    , module Control.Monad.Fail
    , module Data.Either
    , module Data.Maybe
    , module Relude.Monad
    , module Relude.Monad.Either
    , module Relude.Monad.Maybe

      -- * Reexports from Relude.Lifted
    , module Relude.Lifted.Env
    , module Relude.Lifted.Exit
    , module Relude.Lifted.File
    , module Relude.Lifted.Handle
    , module Relude.Lifted.Terminal

      -- * Reexports from Relude
    , module Relude.Applicative
    , module Relude.Base
    , module Relude.Bool
    , module Relude.Container
    , module Relude.Debug
    , module Relude.DeepSeq
    , module Relude.Enum
    , module Relude.Exception
    , module Relude.File
    , module Relude.Foldable
    , module Relude.Function
    , module Relude.Functor
    , module Relude.List
    , module Relude.Monoid
    , module Relude.Nub
    , module Relude.Numeric
    , module Relude.Print
    , module Relude.String
    ) where

import Effectful (Eff, MonadIO (liftIO), (:>))
import Effectful.Error.Static


{- FOURMOLU_DISABLE -}
-- Get all export from Relude except the Relude.Lifted and Relude.Monad modules.
import Relude.Applicative
import Relude.Base
import Relude.Bool
import Relude.Container
import Relude.Debug
import Relude.DeepSeq
import Relude.Enum
import Relude.Exception
import Relude.File
import Relude.Foldable
import Relude.Function
import Relude.Functor
import Relude.List
import Relude.Monoid
import Relude.Nub
import Relude.Numeric
import Relude.Print
import Relude.String

-- From Relude.Lifted, we don't want Relude.Lifted.Concurrent.
import Relude.Lifted.Exit
import Relude.Lifted.Env hiding (lookupEnv)
import Relude.Lifted.File
import Relude.Lifted.Terminal
import Relude.Lifted.Handle

-- From Relude.Monad, we don't want Relude.Monad.Reexport and Relude.Monad.Trans.
import Relude.Monad.Either
import Relude.Monad.Maybe
import Relude.Monad (chainedTo, infinitely)

-- From Relude.Monad.Reexport, we don't want any transformer modules, like the following:
-- Control.Monad.Except
-- Control.Monad.Reader
-- Control.Monad.State.Strict
-- Control.Monad.Trans
-- Control.Monad.Trans.Identity
-- Control.Monad.Trans.Maybe 
import Control.Monad
    ( Monad (return, (>>), (>>=))
    , MonadPlus (..)
    , filterM
    , forever
    , join
    , mapAndUnzipM
    , mfilter
    , replicateM
    , replicateM_
    , zipWithM
    , zipWithM_
    , (<$!>)
    , (<=<)
    , (=<<)
    , (>=>)
    )
import Control.Monad.Fail (MonadFail (..))
import Data.Either
    ( Either (..)
    , either
    , isLeft
    , isRight
    , lefts
    , partitionEithers
    , rights
    )
import Data.Maybe
    ( Maybe (..)
    , catMaybes
    , fromMaybe
    , isJust
    , isNothing
    , listToMaybe
    , mapMaybe
    , maybe
    , maybeToList
    )
{- FOURMOLU_ENABLE -}
