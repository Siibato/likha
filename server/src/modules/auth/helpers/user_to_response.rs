use crate::modules::auth::schema::UserResponse;

pub fn user_to_response(user: &::entity::users::Model) -> UserResponse {
    let is_active = user.account_status != "locked" && user.account_status != "deactivated";

    UserResponse {
        id: user.id,
        username: user.username.clone(),
        full_name: user.full_name.clone(),
        role: user.role.clone(),
        account_status: user.account_status.clone(),
        is_active,
        activated_at: user.activated_at.map(|dt| dt.to_string()),
        created_at: user.created_at.to_string(),
    }
}
