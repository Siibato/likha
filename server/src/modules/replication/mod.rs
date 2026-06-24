pub mod auth;
pub mod discovery;
pub mod dynamic_worker;
pub mod handler;
pub mod peer_manager;
pub mod routes;
pub mod service;
pub mod worker;

pub use discovery::{DiscoveryConfig, DiscoveryService};
pub use dynamic_worker::run_dynamic_replication;
pub use peer_manager::{PeerInfo, PeerManager, PeerStatus};
pub use service::ReplicationService;
