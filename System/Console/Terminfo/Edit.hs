{-# LANGUAGE CPP #-}
#if __GLASGOW_HASKELL__ > 703 &&  __GLASGOW_HASKELL__ < 902
{-# LANGUAGE Safe #-}
#else
{-# LANGUAGE Trustworthy #-}
{-# LANGUAGE QuantifiedConstraints, FlexibleContexts #-}
#endif
-- |
-- Maintainer  : judah.jacobson@gmail.com
-- Stability   : experimental
-- Portability : portable (FFI)
module System.Console.Terminfo.Edit where

import System.Console.Terminfo.Base
#if MIN_VERSION_base(4,16,0)
import GHC.Types (Total)
#endif
-- | Clear the screen, and move the cursor to the upper left.
clearScreen ::
#if MIN_VERSION_base(4,16,0)
  Total Capability =>
#endif
  Capability (LinesAffected -> TermOutput)
clearScreen = fmap ($ []) $ tiGetOutput "clear" 

-- | Clear from beginning of line to cursor.
clearBOL :: (
#if MIN_VERSION_base(4,16,0)
  Total Capability,
#endif
  TermStr s) => Capability s
clearBOL = tiGetOutput1 "el1"

-- | Clear from cursor to end of line.
clearEOL :: (
#if MIN_VERSION_base(4,16,0)
  Total Capability,
#endif
  TermStr s) => Capability s
clearEOL = tiGetOutput1 "el"

-- | Clear display after cursor.
clearEOS ::
#if MIN_VERSION_base(4,16,0)
  Total Capability =>
#endif
  Capability (LinesAffected -> TermOutput)
clearEOS = fmap ($ []) $ tiGetOutput "ed"

