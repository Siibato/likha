use crate::modules::grading::schema::{
    AllGradeDataResponse, GradeItemResponse, GradeScoreResponse,
};
use crate::modules::grading::helpers::deped_weights::transmute_grade;

pub struct SectionInfo {
    pub items: Vec<GradeItemResponse>,
    pub hps_total: f64,
    pub weight: f64,
}

pub struct SectionResult {
    pub scores: Vec<Option<f64>>,
    pub total: Option<f64>,
    pub ps: Option<f64>,
    pub ws: Option<f64>,
}

pub struct StudentRow {
    pub index: usize,
    pub student_id: String,
    pub student_name: String,
    pub ww: SectionResult,
    pub pt: SectionResult,
    pub qa: SectionResult,
    pub initial_grade: Option<f64>,
    pub transmuted_grade: Option<i32>,
}

pub struct GradeTableData {
    pub ww: SectionInfo,
    pub pt: SectionInfo,
    pub qa: SectionInfo,
    pub students: Vec<StudentRow>,
}

impl GradeTableData {
    pub fn build(data: &AllGradeDataResponse) -> Self {
        let period = data.period;

        let quarter_items: Vec<&GradeItemResponse> = data
            .grade_items
            .iter()
            .filter(|i| {
                i.term_number == Some(period)
                    || i.term_number.is_none()
            })
            .collect();

        let ww_items: Vec<GradeItemResponse> = quarter_items
            .iter()
            .filter(|i| i.component == "ww" || i.component == "written_work")
            .map(|i| (*i).clone())
            .collect();
        let pt_items: Vec<GradeItemResponse> = quarter_items
            .iter()
            .filter(|i| i.component == "pt" || i.component == "performance_task")
            .map(|i| (*i).clone())
            .collect();
        let qa_items: Vec<GradeItemResponse> = quarter_items
            .iter()
            .filter(|i| i.component == "qa" || i.component == "period_assessment")
            .map(|i| (*i).clone())
            .collect();

        let ww_hps: f64 = ww_items.iter().map(|i| i.total_points).sum();
        let pt_hps: f64 = pt_items.iter().map(|i| i.total_points).sum();
        let qa_hps: f64 = qa_items.iter().map(|i| i.total_points).sum();

        let ww_weight = data.config.as_ref().map(|c| c.ww_weight).unwrap_or(40.0);
        let pt_weight = data.config.as_ref().map(|c| c.pt_weight).unwrap_or(40.0);
        let qa_weight = data.config.as_ref().map(|c| c.qa_weight).unwrap_or(20.0);

        let ww_section = SectionInfo {
            items: ww_items,
            hps_total: ww_hps,
            weight: ww_weight,
        };
        let pt_section = SectionInfo {
            items: pt_items,
            hps_total: pt_hps,
            weight: pt_weight,
        };
        let qa_section = SectionInfo {
            items: qa_items,
            hps_total: qa_hps,
            weight: qa_weight,
        };

        let tg_lookup: std::collections::HashMap<String, Option<i32>> = data
            .grade_summary
            .students
            .iter()
            .map(|s| (s.student_id.clone(), s.transmuted_grade))
            .collect();

        let score_lookup = build_score_lookup(&data.scores_by_item);

        let students = data
            .grade_summary
            .students
            .iter()
            .enumerate()
            .map(|(i, s)| {
                let student_scores = score_lookup.get(&s.student_id).cloned().unwrap_or_default();
                let ww_result = compute_section(&student_scores, &ww_section);
                let pt_result = compute_section(&student_scores, &pt_section);
                let qa_result = compute_section(&student_scores, &qa_section);

                let initial_grade = compute_initial_grade(&ww_result, &pt_result, &qa_result);
                let stored_tg = tg_lookup.get(&s.student_id).copied().flatten();
                let tg = stored_tg.or_else(|| {
                    initial_grade.map(|ig| transmute_grade(ig))
                });

                StudentRow {
                    index: i + 1,
                    student_id: s.student_id.clone(),
                    student_name: s.student_name.clone(),
                    ww: ww_result,
                    pt: pt_result,
                    qa: qa_result,
                    initial_grade,
                    transmuted_grade: tg,
                }
            })
            .collect();

        Self {
            ww: ww_section,
            pt: pt_section,
            qa: qa_section,
            students,
        }
    }

    pub fn total_columns(&self) -> usize {
        let ww_cols = if !self.ww.items.is_empty() {
            self.ww.items.len() + 3
        } else {
            0
        };
        let pt_cols = if !self.pt.items.is_empty() {
            self.pt.items.len() + 3
        } else {
            0
        };
        let qa_cols = if !self.qa.items.is_empty() {
            self.qa.items.len() + 3
        } else {
            0
        };
        1 + ww_cols + pt_cols + qa_cols + 2
    }
}

fn build_score_lookup(
    scores_by_item: &std::collections::HashMap<String, Vec<GradeScoreResponse>>,
) -> std::collections::HashMap<String, std::collections::HashMap<String, f64>> {
    let mut lookup = std::collections::HashMap::new();
    for (item_id, scores) in scores_by_item {
        for score in scores {
            let effective = score.override_score.or(score.score);
            if let Some(eff) = effective {
                lookup
                    .entry(score.student_id.clone())
                    .or_insert_with(std::collections::HashMap::new)
                    .insert(item_id.clone(), eff);
            }
        }
    }
    lookup
}

fn compute_section(
    student_scores: &std::collections::HashMap<String, f64>,
    section: &SectionInfo,
) -> SectionResult {
    let mut scores = Vec::new();
    let mut total = 0.0;
    let mut has_any = false;

    for item in &section.items {
        let score = student_scores.get(&item.id).copied();
        scores.push(score);
        if let Some(s) = score {
            total += s;
            has_any = true;
        }
    }

    if !has_any || section.hps_total <= 0.0 {
        return SectionResult {
            scores,
            total: None,
            ps: None,
            ws: None,
        };
    }

    let ps = (total / section.hps_total) * 100.0;
    let ws = ps * (section.weight / 100.0);

    SectionResult {
        scores,
        total: Some(total),
        ps: Some(ps),
        ws: Some(ws),
    }
}

fn compute_initial_grade(
    ww: &SectionResult,
    pt: &SectionResult,
    qa: &SectionResult,
) -> Option<f64> {
    let mut sum: Option<f64> = None;
    if let Some(w) = ww.ws {
        sum = Some(sum.unwrap_or(0.0) + w);
    }
    if let Some(w) = pt.ws {
        sum = Some(sum.unwrap_or(0.0) + w);
    }
    if let Some(w) = qa.ws {
        sum = Some(sum.unwrap_or(0.0) + w);
    }
    sum
}
