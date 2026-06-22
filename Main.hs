module Main where

import Data.Function ((&))
import Data.Functor ((<&>))
import Data.Functor.Identity (Identity(runIdentity))
import Data.Maybe (fromMaybe)
import Data.Word (Word8)
import qualified Streamly.Data.Array as Array
import Streamly.Data.Array (Array)
import qualified Streamly.Internal.Data.Array as Array
import qualified Streamly.Data.Stream as Stream
import qualified Streamly.Data.StreamK as StreamK
import Streamly.Data.Stream (Stream)
import qualified Streamly.Data.Fold as Fold
import qualified Streamly.FileSystem.File as File
import qualified Streamly.Unicode.Stream as Unicode
import qualified Streamly.Internal.Unicode.Stream as Unicode
import qualified Streamly.System.Command as Command
import System.Directory (setCurrentDirectory)
import System.Environment (lookupEnv)

main :: IO ()
main = do
  initDebug
  Stream.concatMap formatForDebug files
    & Command.pipeBytes "wl-copy"
    & Stream.fold Fold.drain
  where
    initDebug :: IO ()
    initDebug = do
      mDebugDir <- lookupEnv "BUILD_WORKING_DIRECTORY"
      case mDebugDir of
        Just debugDir -> setCurrentDirectory debugDir
        Nothing       -> pure ()
    files :: Stream IO FilePath
    files = File.read ".debug-files"
              & Unicode.decodeUtf8
              & Unicode.lines Fold.toList
    formatForDebug :: FilePath -> Stream IO Word8
    formatForDebug fileName = beforeContents
      `Stream.append` File.read fileName
      `Stream.append` afterContents
      where
        beforeContents :: Stream IO Word8
        beforeContents = "### "
          ++ fileName
          ++ "\n```"
          ++ fileExtension
          ++ "\n"
          & Stream.fromList
          & Unicode.encodeUtf8
        afterContents :: Stream IO Word8
        afterContents = "\n```\n"
                          & Stream.fromList
                          & Unicode.encodeUtf8
        fileExtension :: String
        fileExtension = if dot `elem` fileName
          then reverse fileName
                 & takeWhile (/= dot)
                 & reverse
          else ""
        dot :: Char
        dot = '.'
