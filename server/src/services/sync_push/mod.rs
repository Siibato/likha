/// Extracts a required field from a sync operation payload.
/// On parse failure, returns early from the enclosing function with an error OperationResult.
///
/// Standard form (uses op.payload):
///   let field = extract_field!(self, op, parse_uuid_field, "field_name");
///
/// Explicit payload form (uses any &serde_json::Value):
///   let field = extract_field!(self, op, q, parse_str_field, "question_text");
macro_rules! extract_field {
    ($self:ident, $op:ident, $method:ident, $field:literal) => {
        match $self.$method(&$op.payload, $field) {
            Ok(v) => v,
            Err(e) => return $self.error_result($op, &e),
        }
    };
    ($self:ident, $op:ident, $payload:expr, $method:ident, $field:literal) => {
        match $self.$method($payload, $field) {
            Ok(v) => v,
            Err(e) => return $self.error_result($op, &e),
        }
    };
}
pub(super) use extract_field;

pub mod sync_push_service;
pub mod push;
pub mod class_ops;
pub mod admin_user_ops;
pub mod assessment_ops;
pub mod question_ops;
pub mod assignment_ops;
pub mod learning_material_ops;
pub mod submission_ops;

pub use sync_push_service::{SyncPushService, OperationResult};