// Helper functions specific to this service
// Add utility functions that support the service operations

use uuid::Uuid;

pub fn generate_service_name_id() -> Uuid {
    Uuid::new_v4()
}

// Add other helper functions as needed
