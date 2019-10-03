{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
module Minicute.Data.GMachine.Global
  ( module Minicute.Data.Common
  , module Minicute.Data.GMachine.Address

  , Global
  , empty
  , allocAddress
  , updateAddress
  , findAddress
  ) where

import Prelude hiding ( fail )

import Control.Lens.At ( at )
import Control.Lens.Getter ( use )
import Control.Lens.Operators
import Control.Lens.TH
import Control.Lens.Wrapped ( _Wrapped )
import Control.Monad.Fail
import Control.Monad.State ( MonadState )
import Data.Data
import GHC.Generics
import Minicute.Data.Common ( Identifier(..) )
import Minicute.Data.GMachine.Address

import qualified Data.Map as Map

newtype Global
  = Global (Map.Map Identifier Address)
  deriving ( Generic
           , Typeable
           , Data
           , Eq
           , Ord
           , Show
           )

makeWrapped ''Global

empty :: Global
empty = Global Map.empty

allocAddress :: (MonadState s m, s ~ Global) => Identifier -> Address -> m ()
allocAddress ident addr = _Wrapped . at ident .= Just addr

updateAddress :: (MonadState s m, s ~ Global, MonadFail m) => Identifier -> Address -> m ()
updateAddress ident addr = do
  mayAddr <- use (_Wrapped . at ident)
  case mayAddr of
    Just _ -> _Wrapped . at ident .= Just addr
    Nothing -> fail $ "updateAddress: No registered address for the identifier " <> show ident

findAddress :: (MonadState s m, s ~ Global, MonadFail m) => Identifier -> m Address
findAddress ident = do
  mayAddr <- use (_Wrapped . at ident)
  case mayAddr of
    Just addr -> pure addr
    Nothing -> fail $ "findAddress: No registered address for the identifier " <> show ident
