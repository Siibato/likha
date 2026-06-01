use uuid::Uuid;
use crate::utils::error::AppResult;
use crate::modules::learning_material::schema::ReorderMaterialsRequest;

impl crate::modules::learning_material::service::LearningMaterialService {
    pub async fn reorder_materials(
        &self,
        class_id: Uuid,
        request: ReorderMaterialsRequest,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        self.verify_teacher_owns_class(class_id, teacher_id).await?;
        if request.material_ids.is_empty() {
            return Ok(());
        }
        self.material_repo.reorder_materials(class_id, request.material_ids).await?;
        Ok(())
    }
}
