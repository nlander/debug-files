module Main where

import qualified Streamly.Data.Stream as Stream
import qualified Streamly.Data.Fold as Fold

main :: IO ()
main = do
  let stringStream = Stream.fromList ["Hello", "Nix", "Bazel", "Haskell", "Streamly"]
  Stream.fold Fold.drain $ Stream.mapM print stringStream
