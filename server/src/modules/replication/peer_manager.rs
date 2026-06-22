use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant};

use tokio::sync::RwLock;

use crate::modules::replication::discovery::Beacon;

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum PeerStatus {
    Active,
    Suspect,
}

#[derive(Clone, Debug)]
pub struct PeerInfo {
    pub node_id: String,
    pub node_ip: String,
    pub api_port: u16,
    pub base_url: String,
    pub last_seen: Instant,
    pub status: PeerStatus,
}

#[derive(Clone)]
pub struct PeerManager {
    peers: Arc<RwLock<HashMap<String, PeerInfo>>>,
    group_id: Option<String>,
    own_node_id: String,
    ttl: Duration,
}

impl PeerManager {
    pub fn new(group_id: Option<String>, own_node_id: String, ttl_seconds: u64) -> Self {
        Self {
            peers: Arc::new(RwLock::new(HashMap::new())),
            group_id,
            own_node_id,
            ttl: Duration::from_secs(ttl_seconds),
        }
    }

    pub async fn handle_beacon(&self, beacon: Beacon) {
        if let Some(required_group) = &self.group_id {
            if &beacon.group_id != required_group {
                return;
            }
        }

        if beacon.node_id == self.own_node_id {
            return;
        }

        let mut peers = self.peers.write().await;
        let base_url = format!("http://{}:{}", beacon.node_ip, beacon.api_port);
        peers.insert(
            beacon.node_id.clone(),
            PeerInfo {
                node_id: beacon.node_id,
                node_ip: beacon.node_ip,
                api_port: beacon.api_port,
                base_url,
                last_seen: Instant::now(),
                status: PeerStatus::Active,
            },
        );
    }

    pub async fn active_peers(&self) -> Vec<PeerInfo> {
        self.peers
            .read()
            .await
            .values()
            .filter(|peer| matches!(peer.status, PeerStatus::Active))
            .cloned()
            .collect()
    }

    pub async fn expire_stale(&self) {
        let mut peers = self.peers.write().await;
        let suspect_after = self.ttl;
        let drop_after = self.ttl * 2;
        peers.retain(|_, peer| {
            let elapsed = Instant::now().duration_since(peer.last_seen);
            if elapsed > drop_after {
                return false;
            }
            if elapsed > suspect_after {
                peer.status = PeerStatus::Suspect;
            } else {
                peer.status = PeerStatus::Active;
            }
            true
        });
    }
}
