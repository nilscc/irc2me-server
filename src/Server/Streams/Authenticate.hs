{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PatternGuards #-}

module Server.Streams.Authenticate where

import Control.Monad

import qualified Data.Text as Text
import qualified Data.Text.Encoding as TE

import Data.ProtocolBuffers

import Database.Query
import Database.Tables.Accounts

import ProtoBuf.Messages.Client
import ProtoBuf.Messages.Server

import Server.Streams

getClientMessage :: Stream PB_ClientMessage
getClientMessage = getMessage

authenticate :: Stream Account
authenticate = do

  msg <- getClientMessage
  case msg of

    _ | Just login <- getField $ auth_login msg
      , Just pw    <- getField $ auth_password msg -> do

        -- run database query
        maccount <- runQuery $ selectAccountByLogin (Text.unpack login)
        case maccount of

          Right (Just account) -> do

            res <- runQuery $ checkPassword account (TE.encodeUtf8 pw)
            case res of
              Right True -> return account
              _          -> throwS "authenticate" $ "Invalid password for user: " ++ Text.unpack login

          _ -> throwS "authenticate" $ "Invalid login: " ++ Text.unpack login

      | otherwise ->
        throwS "authenticate" $ "Unexpected message: " ++ show msg

throwUnauthorized :: Stream a
throwUnauthorized = do

  sendMessage $ responseErrorMessage $ Just "Invalid login/password."

  throwS "unauthorized" "Invalid login/password."