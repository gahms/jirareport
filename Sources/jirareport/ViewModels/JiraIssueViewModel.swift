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
    let allSprints: [JiraSprintLinkViewModel]
}

struct JiraSprintLinkViewModel {
    let id: Int
    let state: SprintState
    let name: String
    let sequence: Int
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
        
        allSprints = dto.fields.sprints.compactMap {
            let values = Self.parseSprints($0)
            guard let sid = values["id"], let id = Int(sid) else { return nil }
            guard let state = SprintState(rawValue: values["state"]?.lowercased() ?? "")
            else { return nil }
            guard let sseq = values["sequence"], let seq = Int(sseq) else { return nil }
            
            let name = values["name"] ?? "-"
            return JiraSprintLinkViewModel(
                id: id,
                state: state,
                name: name,
                sequence: seq
            )
        }
        .sorted(by: \.sequence)
    }
    
    static func parseSprints(_ input: String) -> [String: String] {
        Dictionary(
            uniqueKeysWithValues:
                input.split(separator: ",").compactMap {
                    pair -> (String, String)? in
                    let parts = pair.split(separator: "=", maxSplits: 1)
                    guard parts.count == 2 else { return nil }
                    return (String(parts[0]), String(parts[1]))
                }
        )
    }
}
