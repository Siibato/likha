//! Tests for datetime parsing and formatting utilities

use crate::utils::datetime::{fmt_utc, parse_datetime};
use chrono::{Datelike, NaiveDateTime, Timelike};

#[test]
fn test_parse_datetime_iso_format() {
    let result = parse_datetime("2024-01-15T10:30:00").unwrap();
    assert_eq!(result.year(), 2024);
    assert_eq!(result.month(), 1);
    assert_eq!(result.day(), 15);
    assert_eq!(result.hour(), 10);
    assert_eq!(result.minute(), 30);
    assert_eq!(result.second(), 0);
}

#[test]
fn test_parse_datetime_space_format() {
    let result = parse_datetime("2024-01-15 10:30:00").unwrap();
    assert_eq!(result.year(), 2024);
    assert_eq!(result.month(), 1);
    assert_eq!(result.day(), 15);
}

#[test]
fn test_parse_datetime_with_milliseconds() {
    let result = parse_datetime("2024-01-15T10:30:00.123456").unwrap();
    assert_eq!(result.year(), 2024);
    assert_eq!(result.month(), 1);
    assert_eq!(result.day(), 15);
}

#[test]
fn test_parse_datetime_invalid_format() {
    let result = parse_datetime("15-01-2024 10:30:00");
    assert!(result.is_err());
}

#[test]
fn test_parse_datetime_empty() {
    let result = parse_datetime("");
    assert!(result.is_err());
}

#[test]
fn test_parse_datetime_gibberish() {
    let result = parse_datetime("not a date");
    assert!(result.is_err());
}

#[test]
fn test_fmt_utc() {
    let dt = NaiveDateTime::parse_from_str("2024-01-15T10:30:00", "%Y-%m-%dT%H:%M:%S").unwrap();
    let formatted = fmt_utc(dt);
    assert_eq!(formatted, "2024-01-15T10:30:00Z");
}

#[test]
fn test_fmt_utc_different_times() {
    let dt = NaiveDateTime::parse_from_str("2023-12-25T23:59:59", "%Y-%m-%dT%H:%M:%S").unwrap();
    let formatted = fmt_utc(dt);
    assert_eq!(formatted, "2023-12-25T23:59:59Z");
}

#[test]
fn test_parse_and_format_roundtrip() {
    let original = "2024-06-20T14:45:30";
    let parsed = parse_datetime(original).unwrap();
    let formatted = fmt_utc(parsed);
    assert_eq!(formatted, "2024-06-20T14:45:30Z");
}
