/// Tracks the offset between device clock and server clock.
///
/// The server returns `server_time` with each sync response (in UTC).
/// We calculate: offset = serverTime - deviceTime.now()
/// Then, calls to [now()] return device time adjusted by this offset,
/// ensuring all assessment time comparisons use server-aligned time.
class ServerClockService {
  Duration _offset = Duration.zero;
  bool _hasBeenSynced = false;

  bool get hasBeenSynced => _hasBeenSynced;

  /// Called after each successful sync with the ISO-8601 server_time string.
  /// Computes offset = serverTime - deviceNow and stores it in memory.
  void updateOffset(String serverTimeIso) {
    // Normalize the timestamp to UTC format, handling various server formats
    String normalized = serverTimeIso.replaceAll(RegExp(r'(Z|[+-]\d{2}:\d{2}(Z)?)$'), '');
    final serverTime = DateTime.parse('${normalized}Z').toUtc();
    _offset = serverTime.difference(DateTime.now().toUtc());
    _hasBeenSynced = true;
  }

  /// Returns an adjusted "now" corrected by the server offset.
  /// Falls back to UTC device time if no sync has occurred yet.
  DateTime now() => DateTime.now().toUtc().add(_offset);
}
