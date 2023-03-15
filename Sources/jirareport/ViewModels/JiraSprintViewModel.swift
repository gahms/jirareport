import Foundation

struct JiraSprintViewModel {
    let id: Int
    let state: SprintState
    let name: String
    let startDate: Date?
    let startDateShort: String
    let endDate: Date?
    let completeDate: Date?
    let activateDate: Date?
    let goal: String?
    let issues: [JiraIssueViewModel]
}

extension JiraSprintViewModel {
    init(_ dto: JiraSprintDTO, issues: [JiraIssueViewModel]) {
        id = dto.id
        state = dto.state
        name = dto.name
        startDate = dto.startDate
        startDateShort = dto
            .startDate?.formatted(date: .abbreviated, time: .omitted) ?? "-"
        endDate = dto.endDate
        completeDate = dto.completeDate
        activateDate = dto.activateDate
        goal = dto.goal
        self.issues = issues
    }
}
