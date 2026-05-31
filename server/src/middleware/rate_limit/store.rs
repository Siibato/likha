use std::collections::HashMap;
use std::sync::RwLock;
use std::time::{SystemTime, UNIX_EPOCH};

use super::config::RateLimitPolicy;

struct WindowEntry {
    count: u32,
    window_start_secs: u64,
}

/// Fixed-window rate limiter for a single policy.
///
/// Each key gets its own counter that resets at the start of each window.
/// Uses std::sync::RwLock — the critical section is a single HashMap op (~μs),
/// so blocking is acceptable and avoids async overhead.
pub struct PolicyLimiter {
    max_requests: u32,
    window_secs: u64,
    entries: RwLock<HashMap<String, WindowEntry>>,
}

impl PolicyLimiter {
    fn new(max_requests: u32, window_secs: u64) -> Self {
        Self {
            max_requests,
            window_secs,
            entries: RwLock::new(HashMap::new()),
        }
    }

    /// Returns Ok(()) if the request is allowed, or Err(retry_after_secs) if rate limited.
    pub fn check(&self, key: &str) -> Result<(), u64> {
        let now_secs = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system clock before Unix epoch")
            .as_secs();
        let current_window = (now_secs / self.window_secs) * self.window_secs;

        let mut entries = self.entries.write().expect("rate limit store lock poisoned");

        let entry = entries.entry(key.to_string()).or_insert(WindowEntry {
            count: 0,
            window_start_secs: current_window,
        });

        if entry.window_start_secs < current_window {
            entry.count = 0;
            entry.window_start_secs = current_window;
        }

        if entry.count >= self.max_requests {
            let elapsed = now_secs - current_window;
            let retry_after = self.window_secs.saturating_sub(elapsed).max(1);
            return Err(retry_after);
        }

        entry.count += 1;
        Ok(())
    }
}

/// Holds one PolicyLimiter per rate limit policy. Constructed once at startup
/// and shared via Arc — the outer map is never mutated after construction.
pub struct RateLimitStore {
    limiters: HashMap<&'static str, PolicyLimiter>,
}

impl RateLimitStore {
    pub fn new() -> Self {
        let policies = [
            RateLimitPolicy::PublicStrict,
            RateLimitPolicy::AuthSensitive,
            RateLimitPolicy::StandardRead,
            RateLimitPolicy::StandardWrite,
            RateLimitPolicy::FileUpload,
            RateLimitPolicy::SyncGenerous,
            RateLimitPolicy::AdminOperations,
        ];

        let mut limiters = HashMap::with_capacity(policies.len());
        for policy in policies {
            if let Some((max_requests, window_secs)) = policy.limit() {
                limiters.insert(policy.store_key(), PolicyLimiter::new(max_requests, window_secs));
            }
        }

        Self { limiters }
    }

    /// Returns Ok(()) if allowed, Err(retry_after_secs) if the key has exceeded the policy limit.
    /// Unrestricted policy always returns Ok(()).
    pub fn check(&self, policy: RateLimitPolicy, key: &str) -> Result<(), u64> {
        if policy == RateLimitPolicy::Unrestricted {
            return Ok(());
        }
        match self.limiters.get(policy.store_key()) {
            Some(limiter) => limiter.check(key),
            None => Ok(()),
        }
    }
}

impl Default for RateLimitStore {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_limiter(max: u32, window: u64) -> PolicyLimiter {
        PolicyLimiter::new(max, window)
    }

    #[test]
    fn allows_up_to_limit() {
        let limiter = make_limiter(3, 60);
        assert!(limiter.check("key1").is_ok());
        assert!(limiter.check("key1").is_ok());
        assert!(limiter.check("key1").is_ok());
        assert!(limiter.check("key1").is_err());
    }

    #[test]
    fn different_keys_are_independent() {
        let limiter = make_limiter(1, 60);
        assert!(limiter.check("key_a").is_ok());
        assert!(limiter.check("key_b").is_ok());
        assert!(limiter.check("key_a").is_err());
        assert!(limiter.check("key_b").is_err());
    }

    #[test]
    fn retry_after_is_positive() {
        let limiter = make_limiter(1, 60);
        limiter.check("key").unwrap();
        let retry = limiter.check("key").unwrap_err();
        assert!(retry >= 1);
        assert!(retry <= 60);
    }

    #[test]
    fn store_unrestricted_always_passes() {
        let store = RateLimitStore::new();
        for _ in 0..1000 {
            assert!(store.check(RateLimitPolicy::Unrestricted, "any").is_ok());
        }
    }

    #[test]
    fn store_enforces_policy_limits() {
        let store = RateLimitStore::new();
        let (max, _) = RateLimitPolicy::PublicStrict.limit().unwrap();
        for _ in 0..max {
            assert!(store.check(RateLimitPolicy::PublicStrict, "test_key").is_ok());
        }
        assert!(store.check(RateLimitPolicy::PublicStrict, "test_key").is_err());
    }
}
