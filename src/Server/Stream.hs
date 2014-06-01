{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TupleSections #-}

module Server.Stream
  ( Stream, StreamT
  , throwS
  , runStreamOnHandle
    -- ** Messages
  , getMessage
  ) where

import Control.Applicative
import Control.Arrow
import Control.Monad
import Control.Monad.Trans
import Control.Monad.Trans.Except

import Data.Serialize
import Data.ProtocolBuffers
import Data.ProtocolBuffers.Internal

import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as BL

import System.IO

type Chunks = [B.ByteString]

--------------------------------------------------------------------------------
-- newtype on chunks

newtype StreamT e m a = StreamT { runStreamT :: Chunks -> ExceptT e m (Chunks, a) }

type Stream a = (Applicative m, MonadIO m) => StreamT String m a

instance Monad m => Monad (StreamT e m) where
  return a = StreamT $ \s -> return (s, a)
  m >>= n  = StreamT $ \s -> do
               (s', a) <- runStreamT m s
               runStreamT (n a) s'

instance (Functor m, MonadIO m) => MonadIO (StreamT e m) where
  liftIO f = StreamT $ \s -> (s,) <$> liftIO f


instance Functor m => Functor (StreamT e m) where
  fmap f m = StreamT $ \s ->
    second f `fmap` runStreamT m s

instance (Functor m, Monad m) => Applicative (StreamT e m) where
  pure = return
  (<*>) = ap

--------------------------------------------------------------------------------

throwS :: Monad m => e -> StreamT e m a
throwS e = StreamT $ \_ -> throwE e

chunksFromHandle :: Handle -> IO Chunks
chunksFromHandle h = BL.toChunks <$> BL.hGetContents h

runStreamOnHandle :: (Functor m, MonadIO m) => Handle -> StreamT e m a -> m (Either e a)
runStreamOnHandle h st = do
  s <- liftIO $ chunksFromHandle h
  runExceptT $ snd <$> runStreamT st s

--------------------------------------------------------------------------------
-- messages

getMessage :: Decode a => Stream a
getMessage = StreamT $ \(chunks) ->

  handleChunks chunks $ runGetPartial getVarintPrefixedBS

 where

  handleChunks (chunk : rest) f

    -- skip empty chunks
    | B.null chunk = handleChunks rest f

    | otherwise =

      -- parse chunk
      case f chunk of

        Fail err _ -> throwE $ "Unexpected error: " ++ show err

        Partial f' -> handleChunks rest f'

        Done bs chunk' -> do
          -- try to parse current message
          case runGet decodeMessage bs of
            Left err  -> throwE $ "Failed to parse message: " ++ show err
            Right msg -> return (chunk' : rest, msg)

  handleChunks [] f =

    case f B.empty of
      Done bs _ | Right msg <- runGet decodeMessage bs ->
        return ([], msg)
      _ -> throwE $ "Unexpected end of input."
