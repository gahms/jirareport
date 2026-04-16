import Foundation

struct JiraIssueDTO: Decodable {
    struct NamedField: Decodable {
        let name: String
    }
    struct Fields: Decodable {
        let status: NamedField
        let resolution: NamedField?
        let issueType: NamedField
        let summary: String
        let storyPoints: Double?
        let epicLink: String?
        let sprint: JiraIssueSprintDTO?
        let flagged: Bool
        let sprints: [String]
        
        struct DynamicKey: CodingKey {
            var stringValue: String
            var intValue: Int? { nil }
            
            init?(stringValue: String) {
                self.stringValue = stringValue
            }
            
            init?(intValue: Int) {
                return nil
            }
        }
        
        enum UserInfoKey {
            static let sprintsKey = CodingUserInfoKey(rawValue: "sprintsKey")!
        }

        init(from decoder: Decoder) throws {
            let known = try decoder.container(keyedBy: CodingKeys.self)
            status = try known.decode(NamedField.self, forKey: .status)
            resolution = try known.decodeIfPresent(NamedField.self, forKey: .resolution)
            issueType = try known.decode(NamedField.self, forKey: .issueType)
            summary = try known.decode(String.self, forKey: .summary)
            storyPoints = try known.decodeIfPresent(Double.self, forKey: .storyPoints)
            epicLink = try known.decodeIfPresent(String.self, forKey: .epicLink)
            sprint = try known.decodeIfPresent(JiraIssueSprintDTO.self, forKey: .sprint)
            flagged = try known.decode(Bool.self, forKey: .flagged)

            guard
                let sprintsRuntimeKey = decoder.userInfo[UserInfoKey.sprintsKey] as? String,
                let sprintsDynamicKey = DynamicKey(stringValue: sprintsRuntimeKey)
            else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Missing runtime key for value"
                ))
            }
            
            let dynamic = try decoder.container(keyedBy: DynamicKey.self)
            sprints = try dynamic.decode([String].self, forKey: sprintsDynamicKey)
        }
        
        enum CodingKeys: String, CodingKey {
            case status = "status"
            case resolution = "resolution"
            case issueType = "issuetype"
            case summary = "summary"
            case storyPoints = "customfield_10012"
            case epicLink = "customfield_10890"
            case sprint = "sprint"
            case flagged = "flagged"
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
