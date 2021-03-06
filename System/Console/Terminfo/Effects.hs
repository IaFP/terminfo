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
module System.Console.Terminfo.Effects(
                    -- * Bell alerts
                    bell,visualBell,
                    -- * Text attributes
                    Attributes(..),
                    defaultAttributes,
                    withAttributes,
                    setAttributes,
                    allAttributesOff,
                    -- ** Mode wrappers
                    withStandout,
                    withUnderline,
                    withBold,
                    -- ** Low-level capabilities
                    enterStandoutMode,
                    exitStandoutMode,
                    enterUnderlineMode,
                    exitUnderlineMode,
                    reverseOn,
                    blinkOn,
                    boldOn,
                    dimOn,
                    invisibleOn,
                    protectedOn
                    ) where

import System.Console.Terminfo.Base
import Control.Monad
#if MIN_VERSION_base(4,16,0)
import GHC.Types (Total)
#endif

wrapWith :: (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability s -> Capability s -> Capability (s -> s)
wrapWith start end = do
    s <- start
    e <- end
    return (\t -> s <#> t <#> e)

-- | Turns on standout mode before outputting the given
-- text, and then turns it off.
withStandout ::  (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability (s -> s)
withStandout = wrapWith enterStandoutMode exitStandoutMode

-- | Turns on underline mode before outputting the given
-- text, and then turns it off.
withUnderline ::  (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability (s -> s)
withUnderline = wrapWith enterUnderlineMode exitUnderlineMode

-- | Turns on bold mode before outputting the given text, and then turns
-- all attributes off.
withBold ::  (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability (s -> s)
withBold = wrapWith boldOn allAttributesOff

enterStandoutMode :: (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability s
enterStandoutMode = tiGetOutput1 "smso"

exitStandoutMode :: (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability s
exitStandoutMode = tiGetOutput1 "rmso"

enterUnderlineMode :: (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability s
enterUnderlineMode = tiGetOutput1 "smul"

exitUnderlineMode :: (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability s
exitUnderlineMode = tiGetOutput1 "rmul"

reverseOn ::  (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability s
reverseOn = tiGetOutput1 "rev"

blinkOn ::  (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability s
blinkOn = tiGetOutput1 "blink"

boldOn ::  (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability s
boldOn = tiGetOutput1 "bold"

dimOn ::  (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability s
dimOn = tiGetOutput1 "dim"

invisibleOn ::  (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability s
invisibleOn = tiGetOutput1 "invis"

protectedOn ::  (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability s
protectedOn = tiGetOutput1 "prot"

-- | Turns off all text attributes.  This capability will always succeed, but it has
-- no effect in terminals which do not support text attributes.
allAttributesOff :: (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability s
allAttributesOff = tiGetOutput1 "sgr0" `mplus` return mempty

data Attributes = Attributes {
                    standoutAttr,
                    underlineAttr,
                    reverseAttr,
                    blinkAttr,
                    dimAttr,
                    boldAttr,
                    invisibleAttr,
                    protectedAttr :: Bool
                -- NB: I'm not including the "alternate character set." 
                }

-- | Sets the attributes on or off before outputting the given text,
-- and then turns them all off.  This capability will always succeed; properties
-- which cannot be set in the current terminal will be ignored.
withAttributes :: (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability (Attributes -> s -> s)
withAttributes = do
    set <- setAttributes
    off <- allAttributesOff
    return $ \attrs to -> set attrs <#> to <#> off

-- | Sets the attributes on or off.  This capability will always succeed;
-- properties which cannot be set in the current terminal will be ignored.
setAttributes ::  (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability (Attributes -> s)
setAttributes = usingSGR0 `mplus` manualSets
    where
        usingSGR0 = do
            sgr <- tiGetOutput1 "sgr"
            return $ \a -> let mkAttr f = if f a then 1 else 0 :: Int
                           in sgr (mkAttr standoutAttr)
                                  (mkAttr underlineAttr)
                                  (mkAttr reverseAttr)
                                  (mkAttr blinkAttr)
                                  (mkAttr dimAttr)
                                  (mkAttr boldAttr)
                                  (mkAttr invisibleAttr)
                                  (mkAttr protectedAttr)
                                  (0::Int) -- for alt. character sets
        attrCap ::  (
#if __GLASGOW_HASKELL__ >= 903
                     Total Capability, 
#endif
                     TermStr s) => (Attributes -> Bool) -> Capability s 
                                -> Capability (Attributes -> s)
        attrCap f cap = do {to <- cap; return $ \a -> if f a then to else mempty}
                        `mplus` return (const mempty)
        manualSets = do
            cs <- sequence [attrCap standoutAttr enterStandoutMode
                            , attrCap underlineAttr enterUnderlineMode
                            , attrCap reverseAttr reverseOn
                            , attrCap blinkAttr blinkOn
                            , attrCap boldAttr boldOn
                            , attrCap dimAttr dimOn
                            , attrCap invisibleAttr invisibleOn
                            , attrCap protectedAttr protectedOn
                            ]
            return $ \a -> mconcat $ map ($ a) cs

                                     

-- | These attributes have all properties turned off.
defaultAttributes :: Attributes
defaultAttributes = Attributes False False False False False False False False

-- | Sound the audible bell.
bell ::  (
#if __GLASGOW_HASKELL__ >= 903
  Total Capability, 
#endif
  TermStr s) => Capability s
bell = tiGetOutput1 "bel"

-- | Present a visual alert using the @flash@ capability.
visualBell :: 
#if __GLASGOW_HASKELL__ >= 903
  Total Capability =>
#endif
  Capability TermOutput
visualBell = tiGetOutput1 "flash"
