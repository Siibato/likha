pub mod auth;
pub mod service;
pub mod handler;
pub mod routes;
pub mod worker;
pub mod discovery;
pub mod peer_manager;
pub mod dynamic_worker;

pub use service::ReplicationService;
pub use discovery::{DiscoveryConfig, DiscoveryService};
pub use peer_manager::{PeerInfo, PeerManager, PeerStatus};
pub use dynamic_worker::run_dynamic_replication;
