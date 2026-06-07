use fred::clients::Client as RedisClient;
use fred::interfaces::{ClientLike, KeysInterface};
use fred::types::{config::Config as RedisConfig, Expiration};
use serde::de::DeserializeOwned;
use serde::Serialize;
use std::sync::Arc;
use tracing::{debug, warn};

use super::ttl::CacheTtl;

#[derive(Clone)]
pub struct RedisCache {
    client: RedisClient,
    enabled: bool,
    pub ttl: CacheTtl,
}

impl RedisCache {
    pub async fn new(redis_url: &str, enabled: bool, ttl: CacheTtl) -> Arc<Self> {
        let config = match RedisConfig::from_url(redis_url) {
            Ok(cfg) => cfg,
            Err(e) => {
                warn!("Invalid REDIS_URL format ({}), using default localhost", e);
                RedisConfig::default()
            }
        };

        let client = RedisClient::new(config, None, None, None);
        let _ = client.connect();

        if let Err(e) = client.wait_for_connect().await {
            warn!("Redis not available — cache will fallback to DB reads: {}", e);
        }

        Arc::new(Self {
            client,
            enabled,
            ttl,
        })
    }

    pub async fn get<T: DeserializeOwned>(&self, key: &str) -> Option<T> {
        if !self.enabled {
            return None;
        }

        match self.client.get::<Option<String>, _>(key).await {
            Ok(Some(json)) => match serde_json::from_str::<T>(&json) {
                Ok(value) => {
                    debug!("CACHE HIT: {}", key);
                    Some(value)
                }
                Err(e) => {
                    debug!("CACHE DESER ERROR for {}: {}", key, e);
                    None
                }
            },
            Ok(None) => {
                debug!("CACHE MISS: {}", key);
                None
            }
            Err(e) => {
                debug!("CACHE GET ERROR for {}: {}", key, e);
                None
            }
        }
    }

    pub async fn set<T: Serialize>(
        &self,
        key: &str,
        value: &T,
        ttl_secs: u64,
    ) {
        if !self.enabled {
            return;
        }

        let json = match serde_json::to_string(value) {
            Ok(j) => j,
            Err(e) => {
                warn!("CACHE SERIALIZE ERROR for {}: {}", key, e);
                return;
            }
        };

        match self.client.set::<(), _, _>(
            key,
            json,
            Some(Expiration::EX(ttl_secs as i64)),
            None,
            false,
        ).await {
            Ok(_) => debug!("CACHE SET: {} (ttl={}s)", key, ttl_secs),
            Err(e) => debug!("CACHE SET ERROR for {}: {}", key, e),
        }
    }

    pub async fn del(&self, key: &str) {
        if !self.enabled {
            return;
        }

        match self.client.del::<(), _>(key).await {
            Ok(_) => debug!("CACHE DEL: {}", key),
            Err(e) => debug!("CACHE DEL ERROR for {}: {}", key, e),
        }
    }

    pub async fn del_keys(&self, keys: Vec<String>) {
        if !self.enabled || keys.is_empty() {
            return;
        }

        let count = keys.len();
        match self.client.del::<(), Vec<String>>(keys).await {
            Ok(_) => debug!("CACHE DEL {} keys", count),
            Err(e) => debug!("CACHE DEL ERROR: {}", e),
        }
    }
}
