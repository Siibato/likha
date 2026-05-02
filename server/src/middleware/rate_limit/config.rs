use std::fmt;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RateLimitPolicy {
    Unrestricted,
    PublicStrict,
    AuthSensitive,
    StandardRead,
    StandardWrite,
    FileUpload,
    SyncGenerous,
    AdminOperations,
}

impl RateLimitPolicy {
    /// Returns (max_requests, window_secs), or None for Unrestricted.
    pub fn limit(self) -> Option<(u32, u64)> {
        match self {
            Self::Unrestricted => None,
            Self::PublicStrict => Some((20, 60)),
            Self::AuthSensitive => Some((30, 60)),
            Self::StandardRead => Some((120, 60)),
            Self::StandardWrite => Some((60, 60)),
            Self::FileUpload => Some((30, 60)),
            Self::SyncGenerous => Some((60, 60)),
            Self::AdminOperations => Some((30, 60)),
        }
    }

    pub fn store_key(self) -> &'static str {
        match self {
            Self::Unrestricted => "unrestricted",
            Self::PublicStrict => "public_strict",
            Self::AuthSensitive => "auth_sensitive",
            Self::StandardRead => "standard_read",
            Self::StandardWrite => "standard_write",
            Self::FileUpload => "file_upload",
            Self::SyncGenerous => "sync_generous",
            Self::AdminOperations => "admin_operations",
        }
    }
}

impl fmt::Display for RateLimitPolicy {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.store_key())
    }
}
