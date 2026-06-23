module Main where

import Data.Char (isSpace)
import Data.Function ((&))
import Data.Functor ((<&>))
import Data.List (dropWhileEnd)
import Data.Word (Word8)
import qualified Streamly.Data.Stream as Stream
import Streamly.Data.Stream (Stream)
import qualified Streamly.Data.Fold as Fold
import qualified Streamly.FileSystem.File as File
import qualified Streamly.Unicode.Stream as Unicode
import qualified Streamly.Internal.Unicode.Stream as Unicode
import qualified Streamly.System.Command as Command
import System.Directory (setCurrentDirectory)
import System.Environment (lookupEnv, getArgs)

main :: IO ()
main = do
  args <- getArgs
  initDebug
  debugStream ("--include-buffer" `elem` args)
    & Command.pipeBytes "wl-copy"
    & Stream.fold Fold.drain
  where
    initDebug :: IO ()
    initDebug = do
      mDebugDir <- lookupEnv "BUILD_WORKING_DIRECTORY"
      case mDebugDir of
        Just debugDir -> setCurrentDirectory debugDir
        Nothing       -> do
          paneDir <- Command.toBytes "tmux display-message -p '#{pane_current_path}'"
                       & Unicode.decodeUtf8
                       & Stream.fold Fold.toList
                       <&> dropWhileEnd isSpace
          setCurrentDirectory paneDir
    debugStream :: Bool -> Stream IO Word8
    debugStream True = fileDebugStream
      `Stream.append` tmuxBufferDebugStream
    debugStream False = fileDebugStream
    tmuxBufferDebugStream :: Stream IO Word8
    tmuxBufferDebugStream = beforeBuffer
      `Stream.append` Command.toBytes "tmux show-buffer"
      `Stream.append` afterBuffer
      where
        beforeBuffer :: Stream IO Word8
        beforeBuffer = "### Tmux Clipboard Buffer\n```text\n"
                         & Stream.fromList
                         & Unicode.encodeUtf8
        afterBuffer :: Stream IO Word8
        afterBuffer = "\n```\n"
                        & Stream.fromList
                        & Unicode.encodeUtf8
    fileDebugStream :: Stream IO Word8
    fileDebugStream = Stream.concatMap formatForDebug files
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
          ++ debugHeaderLanguage
          ++ "\n"
          & Stream.fromList
          & Unicode.encodeUtf8
        afterContents :: Stream IO Word8
        afterContents = "\n```\n"
                          & Stream.fromList
                          & Unicode.encodeUtf8
        debugHeaderLanguage :: String
        debugHeaderLanguage = case fileExtension of
          "hs"    -> "haskell"
          "bzl"   -> "starlark"
          "bazel" -> "starlark"
          ext     -> ext
        fileExtension :: String
        fileExtension = if dot `elem` fileName
          then reverse fileName
                 & takeWhile (/= dot)
                 & reverse
          else ""
        dot :: Char
        dot = '.'
