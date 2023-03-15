import Foundation

class TxtOutput {
    func format(sprints: [JiraSprintViewModel]) -> String {
        var doc: String = ""
        
        for sprint in sprints {
            doc.append("\n\n")
            doc.append("--------------------------\n")
            doc.append("[\(sprint.startDateShort)] \(sprint.id) - \(sprint.name) (\(sprint.state))\n")
            doc.append("--------------------------\n")
            for i in sprint.issues {
                let fields: [(String, Int?)] = [
                    (i.key, 10),
                    (i.issueType, 5),
                    (i.summary, 70),
                    (i.epicName, 25),
                    (i.storyPointsFormatted, 4),
                    (i.status, 12),
                    ((i.sprint?.name ?? "")
                     + "/" + (i.sprint?.state ?? ""), 30)
                ]
                let s = fields.map {
                    $0.padding(toLength: $1 ?? $0.count, withPad: " ", startingAt: 0)
                } .joined(separator: " ")
                doc.append(s)
                doc.append("\n")
            }
        }
        
        return doc
    }
}
