{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PatternGuards #-}

module Irc2me.Frontend.Streams.Authenticate where

import Control.Lens.Operators

import qualified Data.Text as Text
import qualified Data.Text.Encoding as TE

import Irc2me.Database.Query
import Irc2me.Database.Tables.Accounts

import Irc2me.Frontend.Messages.Authentication
import Irc2me.Frontend.Messages.Server

import Irc2me.Frontend.Streams.StreamT
import Irc2me.Frontend.Streams.Helper

authenticate :: Stream AccountID
authenticate = do

  msg <- getMessage
  let login = msg ^. authLogin
      pw    = msg ^. authPassword

  -- run database query
  maccount <- showS "authenticate" $ runQuery $ selectAccountByLogin (Text.unpack login)
  case maccount of

    Just account -> do

      ok <- showS "authenticate" $ runQuery $ checkPassword account (TE.encodeUtf8 pw)
      if ok then
        return account
       else
        throwS "authenticate" $ "Invalid password for user: " ++ Text.unpack login

    Nothing -> throwS "authenticate" $ "Invalid login: " ++ Text.unpack login

throwUnauthorized :: Stream a
throwUnauthorized = do

  sendMessage $ responseErrorMessage $ Just "Invalid login/password."

  throwS "unauthorized" "Invalid login/password."
