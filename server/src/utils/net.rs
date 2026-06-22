use std::net::{IpAddr, Ipv4Addr, UdpSocket};

pub fn detect_local_ip() -> String {
    // UDP sockets don't require the target to be reachable; this discovers the
    // outbound interface IP without sending any packets.
    UdpSocket::bind((Ipv4Addr::UNSPECIFIED, 0))
        .and_then(|socket| {
            socket.connect((Ipv4Addr::new(1, 1, 1, 1), 80))?;
            socket.local_addr().map(|addr| addr.ip())
        })
        .map(|ip: IpAddr| ip.to_string())
        .unwrap_or_else(|_| "127.0.0.1".to_string())
}
