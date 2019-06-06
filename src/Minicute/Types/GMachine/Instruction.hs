{-# LANGUAGE OverloadedStrings #-}
module Minicute.Types.GMachine.Instruction where

import Control.Lens.Operators
import Control.Lens.Wrapped ( _Wrapped )
import Minicute.Types.Minicute.Precedence
import Minicute.Types.Minicute.Program

import qualified Data.Map as Map

{-|
Which calling convention we gonna use?
1. Try simple one
    a. caller
        - Push arguments in caller
        - Evaluate result in caller
    b. callee
        - Update results in callee
        - Pop arguments in callee
-}

type GMachineExpression = [Instruction]
type GMachineSupercombinator = (Identifier, Int, GMachineExpression)
type GMachineProgram = [GMachineSupercombinator]

transpileProgram :: MainProgram -> GMachineProgram
transpileProgram program = program ^. _Wrapped <&> transpileSc

initialCode ::[Instruction]
initialCode = [IMakeGlobal "main", IEval]

transpileSc :: MainSupercombinator -> GMachineSupercombinator
transpileSc sc = (scBinder, scArgsLength, scInsts)
  where
    scBinder = sc ^. _supercombinatorBinder

    scInsts = sc ^. _supercombinatorBody & transpileRE scArgsEnv

    scArgsEnv = Map.fromList $ zip scArgs [1..]
    scArgsLength = length scArgs
    scArgs = sc ^. _supercombinatorArguments

{-|
Transpiler for a _R_oot _E_xpression.
-}
transpileRE :: TranspileEEnv -> MainExpression -> GMachineExpression
transpileRE env (EInteger n) = [IPushBasicValue n, IUpdateAsInteger (getEnvSize env)]
transpileRE env (EConstructor tag 0) = [IPushBasicValue tag, IUpdateAsConstructor (getEnvSize env)]
transpileRE env e = transpileSE env e <> [IUpdate envSize1, IPop envSize1, IUnwind]
  where
    envSize1 = getEnvSize1 env

{-|
Transpiler for a _Strict_ _E_xpression.
-}
transpileSE :: TranspileEEnv -> MainExpression -> GMachineExpression
transpileSE _ (EInteger n) = [IMakeInteger n]
transpileSE _ (EConstructor tag arity) = [IMakeConstructor tag arity]
transpileSE env (EVariable v)
  | Just index <- Map.lookup v env = [ICopyArgument index]
  | otherwise = [IMakeGlobal v]
transpileSE env (EApplication2 (EVariableIdentifier op) e1 e2)
  | Just _ <- lookup op binaryPrecedenceTable
  = transpileSE env e1 <> transpileSE (addEnvOffset1 env) e2 <> [IPrimitive (getPrimitiveOperator op)]
transpileSE env (EApplication e1 e2)
  = transpileSE env e1 <> transpileSE (addEnvOffset1 env) e2 <> [IMakeApplication]
transpileSE _ _ = error "Not yet implemented"

type TranspileEEnv = Map.Map Identifier Int

getEnvSize1 :: TranspileEEnv -> Int
getEnvSize1 = (+ 1) . getEnvSize

getEnvSize :: TranspileEEnv -> Int
getEnvSize = Map.size

addEnvOffset1 :: TranspileEEnv -> TranspileEEnv
addEnvOffset1 = Map.map (+ 1)

addEnvOffset :: Int -> TranspileEEnv -> TranspileEEnv
addEnvOffset n = Map.map (+ n)

data Instruction
  {-|
  Basic node creating operations
  -}
  = IMakeInteger Integer
  | IMakeConstructor Integer Integer
  | IMakeApplication
  | IMakeGlobal Identifier

  {-|
  Stack based operations
  -}
  | IPop Int
  | IUpdate Int
  | ICopyArgument Int

  {-|
  Value stack based operations
  -}
  | IPushBasicValue Integer
  | IPushExtractedValue
  | IUpdateAsInteger Int
  | IUpdateAsConstructor Int

  {-|
  Primitive operations
  -}
  | IPrimitive PrimitiveOperator

  {-|
  WHNF related operations
  -}
  | IEval
  | IUnwind
  deriving ( Eq
           , Ord
           , Show
           )

data PrimitiveOperator
  = POAdd
  | POSub
  | POMul
  | PODiv
  deriving ( Eq
           , Ord
           , Show
           )

getPrimitiveOperator :: String -> PrimitiveOperator
getPrimitiveOperator "+" = POAdd
getPrimitiveOperator "-" = POSub
getPrimitiveOperator "*" = POMul
getPrimitiveOperator "/" = PODiv
getPrimitiveOperator _ = error "Not implemented yet"
