#[derive(Debug, Clone)]
pub struct CacheTtl {
    pub list_seconds: u64,
    pub detail_seconds: u64,
    pub static_seconds: u64,
}

impl CacheTtl {
    pub fn from_env() -> Self {
        use std::env;
        Self {
            list_seconds: env::var("CACHE_TTL_LIST_SECONDS")
                .unwrap_or_else(|_| "300".to_string())
                .parse()
                .unwrap_or(300),
            detail_seconds: env::var("CACHE_TTL_DETAIL_SECONDS")
                .unwrap_or_else(|_| "120".to_string())
                .parse()
                .unwrap_or(120),
            static_seconds: env::var("CACHE_TTL_STATIC_SECONDS")
                .unwrap_or_else(|_| "3600".to_string())
                .parse()
                .unwrap_or(3600),
        }
    }
}
