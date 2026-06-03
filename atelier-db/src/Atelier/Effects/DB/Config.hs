module Atelier.Effects.DB.Config
    ( DBConfig (..)
    , DBPools (..)
    , PoolConfig (..)
    , acquireDatabasePool
    , acquireDatabasePools
    )
where

import Atelier.Types.QuietSnake (QuietSnake (..))
import Data.Aeson (FromJSON)

import Hasql.Connection.Setting qualified as Setting
import Hasql.Connection.Setting.Connection qualified as Connection
import Hasql.Connection.Setting.Connection.Param qualified as Param
import Hasql.Pool qualified as Pool
import Hasql.Pool.Config qualified as Pool


-- | Connection pool configuration
data PoolConfig = PoolConfig
    { size :: Int
    , acquisitionTimeoutSeconds :: Int
    , agingTimeoutSeconds :: Int
    , idlenessTimeoutSeconds :: Int
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON) via QuietSnake PoolConfig


-- | Database configuration for a single user
data DBConfig = DBConfig
    { host :: Text
    , port :: Word16
    , user :: Text
    , password :: Text
    , databaseName :: Text
    , pool :: PoolConfig
    }
    deriving stock (Eq, Show)


-- | Separate connection pools for read and write operations
data DBPools = DBPools
    { readerPool :: Pool.Pool
    , writerPool :: Pool.Pool
    }


-- | Acquire a single database connection pool
acquireDatabasePool :: DBConfig -> IO Pool.Pool
acquireDatabasePool config = do
    let settings =
            [ Pool.staticConnectionSettings
                [ Setting.connection
                    $ Connection.params
                        [ Param.host config.host
                        , Param.port config.port
                        , Param.user config.user
                        , Param.password config.password
                        , Param.dbname config.databaseName
                        ]
                ]
            , Pool.size config.pool.size
            , Pool.acquisitionTimeout (fromIntegral config.pool.acquisitionTimeoutSeconds)
            , Pool.agingTimeout (fromIntegral config.pool.agingTimeoutSeconds)
            , Pool.idlenessTimeout (fromIntegral config.pool.idlenessTimeoutSeconds)
            ]

    Pool.acquire $ Pool.settings settings


-- | Acquire both read and write connection pools
-- Uses different database users for read-only and read-write operations
acquireDatabasePools
    :: DBConfig
    -- ^ Read-only user config
    -> DBConfig
    -- ^ Read-write user config
    -> IO DBPools
acquireDatabasePools readerConfig writerConfig = do
    readerPool <- acquireDatabasePool readerConfig
    writerPool <- acquireDatabasePool writerConfig
    pure $ DBPools {readerPool, writerPool}
