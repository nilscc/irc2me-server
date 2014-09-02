{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TemplateHaskell #-}

-- | Module for client to server messages
module Irc2me.ProtoBuf.Messages.Client where

import Data.Text

import GHC.Generics (Generic)

-- protobuf
import Data.ProtocolBuffers
import Data.ProtocolBuffers.Orphans ()
import Data.ProtocolBuffers.TH

-- local
import Irc2me.ProtoBuf.Helper
import Irc2me.ProtoBuf.Messages.System

data ClientMessage = ClientMessage

    -- system
  { _clientResponseID       :: Optional 3  (Value ID_T)
  , _clientSystemMessage    :: Optional 5  (Enumeration SystemMsg)

    -- acount
  , _authLogin              :: Optional 10 (Value Text)
  , _authPassword           :: Optional 11 (Value Text)

    -- identities
  -- , _ident_set              :: Repeated 20  (Message Identity)
  -- , _ident_remove           :: Repeated 21  (Value ID_T)
  -- , _ident_get_all          :: Optional 22  (Value Bool)

    -- networks
  -- , _network_set            :: Repeated 100 (Message Network)
  -- , _network_remove         :: Repeated 101 (Value ID_T)
  -- , _network_get_all_names  :: Optional 102 (Value Bool)
  -- , _network_get_details    :: Repeated 103 (Value ID_T)

  }
  deriving (Eq, Show, Generic)

instance Encode ClientMessage
instance Decode ClientMessage

emptyClientMessage :: ClientMessage
emptyClientMessage = ClientMessage
  { _clientResponseID     = putField Nothing
  , _clientSystemMessage  = putField Nothing
  , _authLogin            = putField Nothing
  , _authPassword         = putField Nothing
  }

------------------------------------------------------------------------------
-- Lenses

makeFieldLenses ''ClientMessage