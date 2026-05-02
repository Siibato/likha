use axum::http::Method;

use super::config::RateLimitPolicy;

/// Maps an HTTP method + path to the appropriate rate limit policy.
/// Paths are already stripped of the /api/v1 prefix by Axum's nest().
pub fn resolve(method: &Method, path: &str) -> RateLimitPolicy {
    // Health and setup endpoints — no rate limiting needed
    if matches!(path, "/health" | "/health/ready" | "/database-id") {
        return RateLimitPolicy::Unrestricted;
    }
    if path.starts_with("/setup/") || path.starts_with("/admin/setup/") {
        return RateLimitPolicy::Unrestricted;
    }

    // Sync endpoints — offline-first mobile app calls these frequently
    if path.starts_with("/sync/") {
        return RateLimitPolicy::SyncGenerous;
    }

    // File upload / download / delete endpoints
    if path.ends_with("/files")
        || path.ends_with("/upload")
        || path.ends_with("/download")
        || path.starts_with("/submission-files/")
        || path.starts_with("/material-files/")
    {
        return RateLimitPolicy::FileUpload;
    }

    // Unauthenticated auth endpoints — strict IP+device keying
    if matches!(path, "/auth/check-username" | "/auth/activate") {
        return RateLimitPolicy::PublicStrict;
    }
    if matches!(path, "/auth/login" | "/auth/refresh") {
        return RateLimitPolicy::AuthSensitive;
    }

    // Admin account management
    if path.starts_with("/auth/accounts") {
        return RateLimitPolicy::AdminOperations;
    }

    // Fallback: keyed by HTTP verb
    if method == Method::GET {
        RateLimitPolicy::StandardRead
    } else {
        RateLimitPolicy::StandardWrite
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn health_is_unrestricted() {
        assert_eq!(resolve(&Method::GET, "/health"), RateLimitPolicy::Unrestricted);
        assert_eq!(resolve(&Method::GET, "/health/ready"), RateLimitPolicy::Unrestricted);
        assert_eq!(resolve(&Method::GET, "/database-id"), RateLimitPolicy::Unrestricted);
    }

    #[test]
    fn setup_is_unrestricted() {
        assert_eq!(resolve(&Method::GET, "/setup/verify"), RateLimitPolicy::Unrestricted);
        assert_eq!(resolve(&Method::GET, "/admin/setup/qr"), RateLimitPolicy::Unrestricted);
    }

    #[test]
    fn sync_routes_are_generous() {
        assert_eq!(resolve(&Method::POST, "/sync/full"), RateLimitPolicy::SyncGenerous);
        assert_eq!(resolve(&Method::POST, "/sync/push"), RateLimitPolicy::SyncGenerous);
        assert_eq!(resolve(&Method::POST, "/sync/deltas"), RateLimitPolicy::SyncGenerous);
    }

    #[test]
    fn file_endpoints_use_upload_policy() {
        assert_eq!(resolve(&Method::POST, "/materials/123/files"), RateLimitPolicy::FileUpload);
        assert_eq!(resolve(&Method::POST, "/assignment-submissions/123/upload"), RateLimitPolicy::FileUpload);
        assert_eq!(resolve(&Method::GET, "/material-files/abc/download"), RateLimitPolicy::FileUpload);
        assert_eq!(resolve(&Method::DELETE, "/submission-files/abc"), RateLimitPolicy::FileUpload);
    }

    #[test]
    fn public_auth_endpoints() {
        assert_eq!(resolve(&Method::POST, "/auth/check-username"), RateLimitPolicy::PublicStrict);
        assert_eq!(resolve(&Method::POST, "/auth/activate"), RateLimitPolicy::PublicStrict);
        assert_eq!(resolve(&Method::POST, "/auth/login"), RateLimitPolicy::AuthSensitive);
        assert_eq!(resolve(&Method::POST, "/auth/refresh"), RateLimitPolicy::AuthSensitive);
    }

    #[test]
    fn admin_account_endpoints() {
        assert_eq!(resolve(&Method::POST, "/auth/accounts"), RateLimitPolicy::AdminOperations);
        assert_eq!(resolve(&Method::GET, "/auth/accounts/123"), RateLimitPolicy::AdminOperations);
        assert_eq!(resolve(&Method::DELETE, "/auth/accounts/123"), RateLimitPolicy::AdminOperations);
    }

    #[test]
    fn standard_fallback_by_method() {
        assert_eq!(resolve(&Method::GET, "/classes"), RateLimitPolicy::StandardRead);
        assert_eq!(resolve(&Method::GET, "/assessments/123"), RateLimitPolicy::StandardRead);
        assert_eq!(resolve(&Method::POST, "/classes"), RateLimitPolicy::StandardWrite);
        assert_eq!(resolve(&Method::PUT, "/classes/123"), RateLimitPolicy::StandardWrite);
        assert_eq!(resolve(&Method::DELETE, "/classes/123"), RateLimitPolicy::StandardWrite);
    }
}
