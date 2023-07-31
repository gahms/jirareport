import Foundation

struct JiraIssueViewModel {
    let key: String
    let status: String
    let issueType: String
    let summary: String
    let storyPoints: Double?
    let storyPointsFormatted: String
    let epic: JiraEpicViewModel?
    let epicName: String
    let sprint: JiraIssueSprintDTO?
    let flagged: Bool
}

extension JiraIssueViewModel {
    init(_ dto: JiraIssueDTO, epicDTO: JiraEpicDTO?) {
        key = dto.key
        status = dto.fields.status.name
        issueType = dto.fields.issueType.name
        summary = dto.fields.summary
        storyPoints = dto.fields.storyPoints
        if let sp = dto.fields.storyPoints {
            storyPointsFormatted = "\(sp)"
        }
        else {
            storyPointsFormatted = "-"
        }
        sprint = dto.fields.sprint
        let epic = JiraEpicViewModel(epicDTO)
        self.epic = epic
        epicName = epic?.epicName ?? "-"
        flagged = dto.fields.flagged
    }
}
