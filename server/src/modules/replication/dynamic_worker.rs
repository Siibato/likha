use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;

use reqwest::Client;
use tokio::task::JoinHandle;

use crate::modules::replication::peer_manager::PeerManager;
use crate::modules::replication::service::ReplicationService;
use crate::modules::replication::worker::spawn_replication_worker;

pub async fn run_dynamic_replication(
    peer_manager: Arc<PeerManager>,
    replication_service: Arc<ReplicationService>,
    replication_secret: String,
    interval: Duration,
) {
    let client = Client::new();
    let mut workers: HashMap<String, JoinHandle<()>> = HashMap::new();

    loop {
        peer_manager.expire_stale().await;
        let active_peers = peer_manager.active_peers().await;

        for peer in &active_peers {
            workers
                .entry(peer.node_id.clone())
                .or_insert_with(|| {
                    spawn_replication_worker(
                        peer.clone(),
                        replication_service.clone(),
                        client.clone(),
                        replication_secret.clone(),
                        interval,
                    )
                });
        }

        workers.retain(|node_id, handle| {
            if active_peers.iter().any(|peer| &peer.node_id == node_id) {
                true
            } else {
                handle.abort();
                false
            }
        });

        tokio::time::sleep(Duration::from_secs(5)).await;
    }
}
