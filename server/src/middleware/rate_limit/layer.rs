use std::future::Future;
use std::pin::Pin;
use std::sync::Arc;
use std::task::{Context, Poll};

use axum::body::Body;
use axum::http::{Request, Response, StatusCode};
use tower::{Layer, Service};

use super::config::RateLimitPolicy;
use super::key_extractor::extract_key;
use super::policy_resolver::resolve;
use super::store::RateLimitStore;

type BoxFuture<T> = Pin<Box<dyn Future<Output = T> + Send + 'static>>;

#[derive(Clone)]
pub struct RateLimitLayer {
    store: Arc<RateLimitStore>,
    jwt_secret: Arc<String>,
}

impl RateLimitLayer {
    pub fn new(store: Arc<RateLimitStore>, jwt_secret: String) -> Self {
        Self {
            store,
            jwt_secret: Arc::new(jwt_secret),
        }
    }
}

impl<S> Layer<S> for RateLimitLayer {
    type Service = RateLimitService<S>;

    fn layer(&self, inner: S) -> Self::Service {
        RateLimitService {
            inner,
            store: Arc::clone(&self.store),
            jwt_secret: Arc::clone(&self.jwt_secret),
        }
    }
}

#[derive(Clone)]
pub struct RateLimitService<S> {
    inner: S,
    store: Arc<RateLimitStore>,
    jwt_secret: Arc<String>,
}

impl<S> Service<Request<Body>> for RateLimitService<S>
where
    S: Service<Request<Body>, Response = Response<Body>, Error = std::convert::Infallible>
        + Clone
        + Send
        + 'static,
    S::Future: Send + 'static,
{
    type Response = Response<Body>;
    type Error = std::convert::Infallible;
    type Future = BoxFuture<Result<Self::Response, Self::Error>>;

    fn poll_ready(&mut self, cx: &mut Context<'_>) -> Poll<Result<(), Self::Error>> {
        self.inner.poll_ready(cx)
    }

    fn call(&mut self, req: Request<Body>) -> Self::Future {
        let store = Arc::clone(&self.store);
        let jwt_secret = Arc::clone(&self.jwt_secret);
        // Clone before moving into async block — inner must be ready (poll_ready was called on self)
        let mut inner = self.inner.clone();

        Box::pin(async move {
            let policy = resolve(req.method(), req.uri().path());

            if policy == RateLimitPolicy::Unrestricted {
                return inner.call(req).await;
            }

            let key = extract_key(req.headers(), req.extensions(), &jwt_secret);

            match store.check(policy, &key) {
                Ok(()) => inner.call(req).await,
                Err(retry_after_secs) => {
                    let body = serde_json::json!({
                        "error": "Too Many Requests",
                        "message": "Rate limit exceeded. Please try again later.",
                        "status_code": 429u16,
                        "remaining_seconds": retry_after_secs as i64,
                        "error_code": "RATE_LIMIT_EXCEEDED"
                    })
                    .to_string();

                    let response = Response::builder()
                        .status(StatusCode::TOO_MANY_REQUESTS)
                        .header("Retry-After", retry_after_secs.to_string())
                        .header("Content-Type", "application/json")
                        .body(Body::from(body))
                        .expect("failed to build 429 response");

                    Ok(response)
                }
            }
        })
    }
}
