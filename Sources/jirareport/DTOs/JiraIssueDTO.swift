import Foundation

struct JiraIssueDTO: Decodable {
    struct NamedField: Decodable {
        let name: String
    }
    struct Fields: Decodable {
        let status: NamedField
        let issueType: NamedField
        let summary: String
        let storyPoints: Double?
        let epicLink: String?
        let sprint: JiraIssueSprintDTO?
        
        enum CodingKeys: String, CodingKey {
            case status = "status"
            case issueType = "issuetype"
            case summary = "summary"
            case storyPoints = "customfield_10012"
            case epicLink = "customfield_10890"
            case sprint = "sprint"
        }
    }
    
    let key: String
    let fields: Fields
}

enum JiraIssueSprintState {
    case future
    
}

struct JiraIssueSprintDTO: Decodable {
    let id: Int
    let state: String
    let name: String
}
