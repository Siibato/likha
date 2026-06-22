use std::sync::Arc;
use std::time::Duration;

use chrono::{DateTime, Utc};
use reqwest::Client;
use tokio::task::JoinHandle;

use crate::modules::replication::peer_manager::PeerInfo;
use crate::modules::replication::service::{ReplicationApplyRequest, ReplicationDeltaResponse, ReplicationService};
use crate::utils::{AppError, AppResult};

pub fn spawn_replication_worker(
    peer: PeerInfo,
    service: Arc<ReplicationService>,
    client: Client,
    secret: String,
    interval: Duration,
) -> JoinHandle<()> {
    tokio::spawn(async move {
        loop {
            if let Err(err) = sync_once(&peer, &service, &client, &secret).await {
                tracing::warn!(target: "replication", peer = %peer.node_id, "Replication cycle failed: {}", err);
            }
            tokio::time::sleep(interval).await;
        }
    })
}

async fn sync_once(
    peer: &PeerInfo,
    service: &ReplicationService,
    client: &Client,
    secret: &str,
) -> AppResult<()> {
    let last_sync = service
        .get_last_sync(&peer.node_id)
        .await?
        .unwrap_or_else(|| DateTime::<Utc>::from_timestamp(0, 0).unwrap());

    let response: ReplicationDeltaResponse = client
        .get(format!("{}/api/v1/replication/deltas", peer.base_url))
        .bearer_auth(secret)
        .query(&[("since", last_sync.to_rfc3339())])
        .send()
        .await
        .map_err(|err| AppError::InternalServerError(err.to_string()))?
        .json()
        .await
        .map_err(|err| AppError::InternalServerError(err.to_string()))?;

    let apply_request = ReplicationApplyRequest {
        source_node_id: response.node_id.clone(),
        deltas: response.deltas.clone(),
    };

    service.apply_deltas(apply_request).await?;

    let server_dt = DateTime::parse_from_rfc3339(&response.server_time)
        .map_err(|err| AppError::InternalServerError(err.to_string()))?
        .with_timezone(&Utc);
    service.set_last_sync(&peer.node_id, server_dt).await?;
    Ok(())
}
