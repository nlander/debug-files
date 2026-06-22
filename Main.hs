{-# LANGUAGE OverloadedStrings #-}
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

main :: IO ()
main = Stream.concatMap formatForDebug files
         & Command.pipeBytes "wl-copy"
         & Stream.fold Fold.drain
  where
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
        beforeContents = Array.fromList "### "
          `StreamK.cons` fileNameA
          `StreamK.cons` Array.fromList "\n```"
          `StreamK.cons` fileExtension
          `StreamK.cons` Array.fromList "\n"
          `StreamK.cons` StreamK.nil
          & Array.fromChunksK
          <&> Array.read
          & Stream.concatEffect
          & Unicode.encodeUtf8
        afterContents :: Stream IO Word8
        afterContents = "\n```\n"
                          & Stream.morphInner (pure . runIdentity)
                          & Unicode.encodeUtf8
        fileExtension :: Array Char
        fileExtension = if hasExtension
          then Array.splitOn (== '.') fileNameA
                 & Stream.fold Fold.latest
                 & runIdentity
                 & fromMaybe Array.empty
          else Array.empty
        hasExtension :: Bool
        hasExtension = Array.foldr checkForDot False fileNameA
        checkForDot :: Char -> Bool -> Bool
        checkForDot '.' _ = True
        checkForDot _   b = b
        fileNameA :: Array Char
        fileNameA = Array.fromList fileName
