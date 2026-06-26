use fred::clients::Client as RedisClient;
use fred::interfaces::{ClientLike, KeysInterface};
use fred::types::{config::Config as RedisConfig, Expiration};
use serde::de::DeserializeOwned;
use serde::Serialize;
use std::sync::Arc;
use std::time::Duration;
use tokio::time::timeout;
use tracing::{debug, warn};

use super::ttl::CacheTtl;

const REDIS_TIMEOUT: Duration = Duration::from_secs(2);

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

        let mut effective_enabled = enabled;
        if let Err(e) = client.wait_for_connect().await {
            warn!(
                "Redis not available — cache disabled, falling back to DB reads: {}",
                e
            );
            effective_enabled = false;
        }

        Arc::new(Self {
            client,
            enabled: effective_enabled,
            ttl,
        })
    }

    pub async fn get<T: DeserializeOwned>(&self, key: &str) -> Option<T> {
        if !self.enabled {
            return None;
        }

        let result = timeout(REDIS_TIMEOUT, self.client.get::<Option<String>, _>(key)).await;
        match result {
            Ok(Ok(cached)) => match cached {
                Some(json) => match serde_json::from_str::<T>(&json) {
                    Ok(value) => {
                        debug!("CACHE HIT: {}", key);
                        Some(value)
                    }
                    Err(e) => {
                        debug!("CACHE DESER ERROR for {}: {}", key, e);
                        None
                    }
                },
                None => {
                    debug!("CACHE MISS: {}", key);
                    None
                }
            },
            Ok(Err(e)) => {
                debug!("CACHE GET ERROR for {}: {}", key, e);
                None
            }
            Err(_) => {
                debug!("CACHE GET TIMEOUT for {}: Redis operation timed out", key);
                None
            }
        }
    }

    pub async fn set<T: Serialize>(&self, key: &str, value: &T, ttl_secs: u64) {
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

        match timeout(
            REDIS_TIMEOUT,
            self.client.set::<(), _, _>(
                key,
                json,
                Some(Expiration::EX(ttl_secs as i64)),
                None,
                false,
            ),
        )
        .await
        {
            Ok(Ok(_)) => debug!("CACHE SET: {} (ttl={}s)", key, ttl_secs),
            Ok(Err(e)) => debug!("CACHE SET ERROR for {}: {}", key, e),
            Err(_) => debug!("CACHE SET TIMEOUT for {}: Redis operation timed out", key),
        }
    }

    pub async fn del(&self, key: &str) {
        if !self.enabled {
            return;
        }

        match timeout(REDIS_TIMEOUT, self.client.del::<(), _>(key)).await {
            Ok(Ok(_)) => debug!("CACHE DEL: {}", key),
            Ok(Err(e)) => debug!("CACHE DEL ERROR for {}: {}", key, e),
            Err(_) => debug!("CACHE DEL TIMEOUT for {}: Redis operation timed out", key),
        }
    }

    pub async fn del_keys(&self, keys: Vec<String>) {
        if !self.enabled || keys.is_empty() {
            return;
        }

        let count = keys.len();
        match timeout(REDIS_TIMEOUT, self.client.del::<(), Vec<String>>(keys)).await {
            Ok(Ok(_)) => debug!("CACHE DEL {} keys", count),
            Ok(Err(e)) => debug!("CACHE DEL ERROR: {}", e),
            Err(_) => debug!(
                "CACHE DEL TIMEOUT: Redis operation timed out for {} keys",
                count
            ),
        }
    }
}
