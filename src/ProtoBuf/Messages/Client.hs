{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TemplateHaskell #-}

-- | Module for client to server messages
module ProtoBuf.Messages.Client where

import Control.Lens.TH

import Data.ProtocolBuffers
import Data.Text
import Data.Monoid
import Data.Word

import GHC.Generics (Generic)

import ProtoBuf.Instances ()
import ProtoBuf.Messages.Identity
import ProtoBuf.Messages.Network
import ProtoBuf.Messages.SystemMsg

data PB_List
  = PB_ListIdentities
  | PB_ListNetworks
  | PB_ListChannels
  deriving (Eq, Enum, Show)

data PB_ClientMessage = PB_ClientMessage
  { -- acount
    _auth_login          :: Optional 1 (Value Text)
  , _auth_password       :: Optional 2 (Value Text)

    -- system
  , _client_system_msg   :: Optional 5 (Enumeration PB_SystemMsg)

    -- identities
  , _identity_add        :: Repeated 11  (Message PB_Identity)
  , _identity_remove     :: Repeated 12  (Message PB_Identity)

    -- networks
  , _network_add         :: Repeated 101 (Message PB_Network)
  , _network_remove      :: Repeated 102 (Message PB_Network)

  , _network_get_list    :: Optional 103 (Value Bool)
  }
  deriving (Eq, Show, Generic)

instance Encode PB_ClientMessage
instance Decode PB_ClientMessage

makeLenses ''PB_ClientMessage

emptyClientMessage :: PB_ClientMessage
emptyClientMessage = PB_ClientMessage
  -- account
  mempty
  mempty
  -- system
  mempty
  -- identities
  mempty
  mempty
  -- networks
  mempty
  mempty
  mempty

--------------------------------------------------------------------------------
-- Requests

data Request
  = SetOpMode
  | GetBacklog
  deriving (Eq, Enum, Show)

data OpMode
  = OpModeStandard
  | OpModeBackground
  deriving (Eq, Enum, Show)

data PB_Request = PB_Request
  { rq_request          :: Required 1  (Enumeration Request)
    -- mode changes
  , rq_opmode           :: Optional 10 (Enumeration OpMode)
    -- message transfer
  , rq_msg_max_backlog  :: Optional 20 (Value Word32)
  }
  deriving (Generic, Show)

instance Encode PB_Request
instance Decode PB_Request
