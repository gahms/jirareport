import Foundation

struct JiraIssuesListDTO: Decodable {
    let startAt: Int
    let maxResults: Int
    let total: Int
    let issues: [JiraIssueDTO]
}
