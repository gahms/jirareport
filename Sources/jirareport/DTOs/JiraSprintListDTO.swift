import Foundation

struct JiraSprintListDTO: Decodable {
    let startAt: Int
    let maxResults: Int
    let isLast: Bool
    let values: [JiraSprintDTO]
}

enum SprintState: String, Decodable {
    case closed
    case active
    case future
}

struct JiraSprintDTO: Decodable {
    let id: Int
    let state: SprintState
    let name: String
    let startDate: Date?
    let endDate: Date?
    let completeDate: Date?
    let activateDate: Date?
    let goal: String?
}
