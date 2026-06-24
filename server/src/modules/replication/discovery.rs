use std::net::{Ipv4Addr, SocketAddr};
use std::sync::Arc;
use std::time::Duration;

use ring::hmac;
use serde::{Deserialize, Serialize};
use tokio::net::UdpSocket;

use crate::utils::{AppError, AppResult};

#[derive(Clone, Debug)]
pub struct DiscoveryConfig {
    pub multicast_addr: SocketAddr,
    pub group_id: String,
    pub node_id: String,
    pub node_ip: String,
    pub api_port: u16,
    pub discovery_port: u16,
    pub beacon_interval: Duration,
    pub peer_ttl: u64,
    pub replication_secret: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Beacon {
    pub version: u8,
    pub group_id: String,
    pub node_id: String,
    pub node_ip: String,
    pub api_port: u16,
    pub discovery_port: u16,
    pub timestamp: String,
    pub ttl: u64,
    pub hmac: String,
}

#[derive(Clone)]
pub struct DiscoveryService {
    socket: Arc<UdpSocket>,
    multicast: SocketAddr,
    config: DiscoveryConfig,
    hmac_key: hmac::Key,
}

impl DiscoveryService {
    pub async fn new(config: DiscoveryConfig) -> AppResult<Self> {
        let socket = UdpSocket::bind(SocketAddr::from(([0, 0, 0, 0], config.discovery_port)))
            .await
            .map_err(|err| {
                AppError::InternalServerError(format!("Failed to bind discovery socket: {}", err))
            })?;

        if let SocketAddr::V4(multicast_v4) = config.multicast_addr {
            socket
                .join_multicast_v4(*multicast_v4.ip(), Ipv4Addr::UNSPECIFIED)
                .map_err(|err| {
                    AppError::InternalServerError(format!(
                        "Failed to join multicast group: {}",
                        err
                    ))
                })?;
        }

        socket.set_broadcast(true).map_err(|err| {
            AppError::InternalServerError(format!("Failed to enable broadcast: {}", err))
        })?;

        let hmac_key = hmac::Key::new(
            hmac::HMAC_SHA256,
            format!("beacon:{}", config.replication_secret).as_bytes(),
        );

        Ok(Self {
            socket: Arc::new(socket),
            multicast: config.multicast_addr,
            config,
            hmac_key,
        })
    }

    pub async fn announce(&self) -> AppResult<()> {
        let beacon = self.build_beacon();
        let bytes = serde_json::to_vec(&beacon).map_err(|err| {
            AppError::InternalServerError(format!("Failed to encode beacon: {}", err))
        })?;
        self.socket
            .send_to(&bytes, self.multicast)
            .await
            .map_err(|err| {
                AppError::InternalServerError(format!("Failed to send beacon: {}", err))
            })?;
        Ok(())
    }

    pub async fn recv_beacon(&self) -> AppResult<Beacon> {
        let mut buf = vec![0u8; 2048];
        let (len, _) = self.socket.recv_from(&mut buf).await.map_err(|err| {
            AppError::InternalServerError(format!("Failed to receive beacon: {}", err))
        })?;
        buf.truncate(len);

        let beacon: Beacon = serde_json::from_slice(&buf)
            .map_err(|err| AppError::BadRequest(format!("Invalid beacon payload: {}", err)))?;
        Ok(beacon)
    }

    fn build_beacon(&self) -> Beacon {
        let mut beacon = Beacon {
            version: 1,
            group_id: self.config.group_id.clone(),
            node_id: self.config.node_id.clone(),
            node_ip: self.config.node_ip.clone(),
            api_port: self.config.api_port,
            discovery_port: self.config.discovery_port,
            timestamp: chrono::Utc::now().to_rfc3339(),
            ttl: self.config.peer_ttl,
            hmac: String::new(),
        };

        let payload = self.canonical_beacon_payload(&beacon);
        let signature = hmac::sign(&self.hmac_key, payload.as_bytes());
        beacon.hmac = hex::encode(signature.as_ref());
        beacon
    }

    pub fn verify_beacon(&self, beacon: &Beacon) -> bool {
        let payload = self.canonical_beacon_payload(beacon);
        let expected = match hex::decode(&beacon.hmac) {
            Ok(bytes) => bytes,
            Err(_) => return false,
        };
        hmac::verify(&self.hmac_key, payload.as_bytes(), &expected).is_ok()
    }

    fn canonical_beacon_payload(&self, beacon: &Beacon) -> String {
        format!(
            "{}|{}|{}|{}|{}|{}|{}|{}",
            beacon.version,
            beacon.group_id,
            beacon.node_id,
            beacon.node_ip,
            beacon.api_port,
            beacon.discovery_port,
            beacon.ttl,
            beacon.timestamp
        )
    }
}
