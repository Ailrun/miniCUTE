module Main
  ( main
  ) where

import Language.Haskell.HLint3 (hlint)
import System.Exit (exitFailure, exitSuccess)

main :: IO ()
main =
  do
    -- This 'putStrLn' is to format stack test output
    putStrLn ""
    let
      hlintArgs =
        [ "src"
        , "--hint=../hlint.yml"
        ]
    hints <- hlint hlintArgs
    if null hints
    then exitSuccess
    else exitFailure
