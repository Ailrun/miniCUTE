{-# OPTIONS_GHC -fno-warn-missing-pattern-synonym-signatures #-}
-- |
-- TODO: remove the following option
{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveLift #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE LiberalTypeSynonyms #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PatternSynonyms #-}
module Minicute.Types.Minicute.Annotated.Expression
  ( module Minicute.Data.Fix
  , module Minicute.Types.Minicute.Common
  , module Minicute.Types.Minicute.Expression


  , AnnotatedExpression_( .. )

  , AnnotatedExpression
  , MainAnnotatedExpression
  , pattern AnnotatedExpression
  , pattern AEInteger
  , pattern AEConstructor
  , pattern AEVariable
  , pattern AEVariableIdentifier
  , pattern AEApplication
  , pattern AEApplication2
  , pattern AEApplication3
  , pattern AELet
  , pattern AEMatch

  , AnnotatedExpressionL
  , MainAnnotatedExpressionL
  , pattern AnnotatedExpressionL
  , pattern AELInteger
  , pattern AELConstructor
  , pattern AELVariable
  , pattern AELVariableIdentifier
  , pattern AELApplication
  , pattern AELApplication2
  , pattern AELApplication3
  , pattern AELLet
  , pattern AELMatch
  , pattern AELLambda
  , pattern AELExpression

  , _annotation
  ) where

import Control.Lens.Lens ( lens )
import Control.Lens.Type
import Data.Data
import Data.Text.Prettyprint.Doc ( Pretty(..) )
import Data.Text.Prettyprint.Doc.Minicute
import GHC.Generics
import GHC.Show ( appPrec, appPrec1 )
import Language.Haskell.TH.Syntax
import Minicute.Data.Fix
import Minicute.Types.Minicute.Common
import Minicute.Types.Minicute.Expression
import Minicute.Types.Minicute.Precedence

import qualified Data.Text.Prettyprint.Doc as PP


newtype AnnotatedExpression_ ann wExpr (expr_ :: * -> *) a
  = AnnotatedExpression_ (ann, wExpr expr_ a)
  deriving ( Generic
           , Typeable
           , Data
           , Lift
           , Eq
           , Ord
           , Show
           )

type AnnotatedExpression ann = Fix2 (AnnotatedExpression_ ann Expression_)
type MainAnnotatedExpression ann = AnnotatedExpression ann Identifier
pattern AnnotatedExpression ann expr = Fix2 (AnnotatedExpression_ (ann, expr))
{-# COMPLETE AnnotatedExpression #-}
pattern AEInteger ann n = AnnotatedExpression ann (EInteger_ n)
pattern AEConstructor ann tag args = AnnotatedExpression ann (EConstructor_ tag args)
pattern AEVariable ann v = AnnotatedExpression ann (EVariable_ v)
pattern AEVariableIdentifier ann v = AnnotatedExpression ann (EVariable_ (Identifier v))
pattern AEApplication ann e1 e2 = AnnotatedExpression ann (EApplication_ e1 e2)
pattern AEApplication2 ann2 ann1 e1 e2 e3 = AEApplication ann2 (AEApplication ann1 e1 e2) e3
pattern AEApplication3 ann3 ann2 ann1 e1 e2 e3 e4 = AEApplication ann3 (AEApplication2 ann2 ann1 e1 e2 e3) e4
pattern AELet ann flag lds e = AnnotatedExpression ann (ELet_ flag lds e)
pattern AEMatch ann e mcs = AnnotatedExpression ann (EMatch_ e mcs)
{-# COMPLETE AEInteger, AEConstructor, AEVariable, AEApplication, AELet, AEMatch #-}
{-# COMPLETE AEInteger, AEConstructor, AEVariableIdentifier, AEApplication, AELet, AEMatch #-}

instance {-# OVERLAPS #-} (Show ann, Show a) => Show (AnnotatedExpression ann a) where
  showsPrec p (AEInteger ann n)
    = showParen (p > appPrec)
      $ showString "AEInteger " . showsPrec appPrec1 ann . showString " " . showsPrec appPrec1 n
  showsPrec p (AEConstructor ann tag args)
    = showParen (p > appPrec)
      $ showString "AEConstructor " . showsPrec appPrec1 ann . showString " " . showsPrec appPrec1 tag . showString " " . showsPrec appPrec1 args
  showsPrec p (AEVariable ann v)
    = showParen (p > appPrec)
      $ showString "AEVariable " . showsPrec appPrec1 ann . showString " " . showsPrec appPrec1 v
  showsPrec p (AEApplication ann e1 e2)
    = showParen (p > appPrec)
      $ showString "AEApplication " . showsPrec appPrec1 ann . showString " " . showsPrec appPrec1 e1 . showString " " . showsPrec appPrec1 e2
  showsPrec p (AELet ann flag lds e)
    = showParen (p > appPrec)
      $ showString "AELet " . showsPrec appPrec1 ann . showString " " . showsPrec appPrec1 flag . showString " " . showsPrec appPrec1 lds . showString " " . showsPrec appPrec1 e
  showsPrec p (AEMatch ann e mcs)
    = showParen (p > appPrec)
      $ showString "AEMatch " . showsPrec appPrec1 ann . showString " " . showsPrec appPrec1 e . showString " " . showsPrec appPrec1 mcs

instance (Pretty ann, Pretty a, Pretty (wExpr expr_ a)) => Pretty (AnnotatedExpression_ ann wExpr expr_ a) where
  pretty (AnnotatedExpression_ (ann, expr))
    = PP.parens (pretty ann PP.<> PP.comma PP.<+> pretty expr)

instance (Pretty ann, Pretty a, Pretty (wExpr expr_ a)) => PrettyPrec (AnnotatedExpression_ ann wExpr expr_ a)

instance (Pretty ann, Pretty a) => Pretty (AnnotatedExpression ann a) where
  pretty (AEApplication2 ann2 ann1 (AEVariableIdentifier annOp op) e1 e2)
    | op `elem` fmap fst binaryPrecedenceTable
    = PP.parens ((PP.hsep . PP.punctuate PP.comma . fmap pretty $ [ann2, ann1, annOp]) PP.<> PP.comma PP.<+> prettyBinaryExpressionPrec 0 op e1 e2)
  pretty expr = pretty (unFix2 expr)

instance (Pretty ann, Pretty a) => PrettyPrec (AnnotatedExpression ann a)

type AnnotatedExpressionL ann = Fix2 (AnnotatedExpression_ ann ExpressionL_)
type MainAnnotatedExpressionL ann = AnnotatedExpressionL ann Identifier
pattern AnnotatedExpressionL ann expr = Fix2 (AnnotatedExpression_ (ann, expr))
{-# COMPLETE AnnotatedExpressionL #-}
pattern AELInteger ann n = AELExpression ann (EInteger_ n)
pattern AELConstructor ann tag args = AELExpression ann (EConstructor_ tag args)
pattern AELVariable ann v = AELExpression ann (EVariable_ v)
pattern AELVariableIdentifier ann v = AELExpression ann (EVariable_ (Identifier v))
pattern AELApplication ann e1 e2 = AELExpression ann (EApplication_ e1 e2)
pattern AELApplication2 ann2 ann1 e1 e2 e3 = AELApplication ann2 (AELApplication ann1 e1 e2) e3
pattern AELApplication3 ann3 ann2 ann1 e1 e2 e3 e4 = AELApplication ann3 (AELApplication2 ann2 ann1 e1 e2 e3) e4
pattern AELLet ann flag lds e = AELExpression ann (ELet_ flag lds e)
pattern AELMatch ann e mcs = AELExpression ann (EMatch_ e mcs)
pattern AELLambda ann as e = AnnotatedExpressionL ann (ELLambda_ as e)
{-# COMPLETE AELInteger, AELConstructor, AELVariable, AELApplication, AELLet, AELMatch, AELLambda #-}
{-# COMPLETE AELInteger, AELConstructor, AELVariableIdentifier, AELApplication, AELLet, AELMatch, AELLambda #-}
pattern AELExpression ann expr = AnnotatedExpressionL ann (ELExpression_ expr)
{-# COMPLETE AELExpression, AELLambda #-}

instance {-# OVERLAPS #-} (Show ann, Show a) => Show (AnnotatedExpressionL ann a) where
  showsPrec p (AELInteger ann n)
    = showParen (p > appPrec)
      $ showString "AELInteger " . showsPrec appPrec1 ann . showString " " . showsPrec appPrec1 n
  showsPrec p (AELConstructor ann tag args)
    = showParen (p > appPrec)
      $ showString "AELConstructor " . showsPrec appPrec1 ann . showString " " . showsPrec appPrec1 tag . showString " " . showsPrec appPrec1 args
  showsPrec p (AELVariable ann v)
    = showParen (p > appPrec)
      $ showString "AELVariable " . showsPrec appPrec1 ann . showString " " . showsPrec appPrec1 v
  showsPrec p (AELApplication ann e1 e2)
    = showParen (p > appPrec)
      $ showString "AELApplication " . showsPrec appPrec1 ann . showString " " . showsPrec appPrec1 e1 . showString " " . showsPrec appPrec1 e2
  showsPrec p (AELLet ann flag lds e)
    = showParen (p > appPrec)
      $ showString "AELLet " . showsPrec appPrec1 ann . showString " " . showsPrec appPrec1 flag . showString " " . showsPrec appPrec1 lds . showString " " . showsPrec appPrec1 e
  showsPrec p (AELMatch ann e mcs)
    = showParen (p > appPrec)
      $ showString "AELMatch " . showsPrec appPrec1 ann . showString " " . showsPrec appPrec1 e . showString " " . showsPrec appPrec1 mcs
  showsPrec p (AELLambda ann as e)
    = showParen (p > appPrec)
      $ showString "AELLambda " . showsPrec appPrec1 ann . showString " " . showsPrec appPrec1 as . showString " " . showsPrec appPrec1 e

instance (Pretty ann, Pretty a) => Pretty (AnnotatedExpressionL ann a) where
  pretty (AELApplication2 ann2 ann1 (AELVariableIdentifier annOp op) e1 e2)
    | op `elem` fmap fst binaryPrecedenceTable
    = PP.parens ((PP.hsep . PP.punctuate PP.comma . fmap pretty $ [ann2, ann1, annOp]) PP.<> PP.comma PP.<+> prettyBinaryExpressionPrec 0 op e1 e2)
  pretty expr = pretty (unFix2 expr)

instance (Pretty ann, Pretty a) => PrettyPrec (AnnotatedExpressionL ann a)

_annotation :: Lens (AnnotatedExpression_ ann wExpr expr_ a) (AnnotatedExpression_ ann' wExpr expr_ a) ann ann'
_annotation = lens getter setter
  where
    getter (AnnotatedExpression_ (ann, _)) = ann
    setter (AnnotatedExpression_ (_, expr)) ann = AnnotatedExpression_ (ann, expr)
{-# INLINEABLE _annotation #-}
