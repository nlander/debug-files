module Main where

import Data.Function ((&))
import Data.Word (Word8)
import qualified Streamly.Data.Stream as Stream
import Streamly.Data.Stream (Stream)
import qualified Streamly.Data.Fold as Fold
import qualified Streamly.FileSystem.File as File
import qualified Streamly.Unicode.Stream as Unicode
import qualified Streamly.Internal.Unicode.Stream as Unicode

main :: IO ()
main = undefined
  where
    formatForDebug :: FilePath -> Stream IO Word8
    formatForDebug fileName = undefined
      where
        beforeContents :: Stream IO Word8
        beforeContents = undefined
    files :: Stream IO FilePath
    files = File.read ".debug-files"
              & Unicode.decodeUtf8
              & Unicode.lines Fold.toList
