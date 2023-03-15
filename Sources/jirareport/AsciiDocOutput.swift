import Foundation

class AsciiDocOutput {
    var preable: String = """
    :pdf-page-margin: [1cm, 1cm]
    :pdf-theme: jirareport-theme.yml
    :icons: font
    :icon-set: fas
    :table-caption!:
    """
    var title: String?
    
    func format(sprints: [JiraSprintViewModel]) -> String {
        var doc: String = preable
        doc.append("\n\n")
        if let title {
            doc.append("= \(title)\n\n")
        }
        
        for sprint in sprints {
            doc.append("== \(sprint.name)\n\n")
            
            /*
            doc.append("[discrete]\n")
            switch sprint.state {
            case .closed:
                doc.append("===== [.done]#DONE#")
            case .active:
                doc.append("===== [.inprogress]#IN PROGRESS...#")
            case .future:
                doc.append("===== [.todo]#TODO#")
            }
            doc.append("\n\n")
             */
            switch sprint.state {
            case .closed:
                doc.append(".[.done]#DONE#")
            case .active:
                doc.append(".[.inprogress]#IN PROGRESS...#")
            case .future:
                doc.append(".[.todo]#TODO#")
            }
            doc.append("\n[%breakable]\n")

            //doc.append("[cols=\"13%,8%,52%,12%,8%,7%\"]\n")
            doc.append("[cols=\"11%,8%,52%,16%,7%,7%\"]\n")
            doc.append("|===\n")
            doc.append(
              """
              | Key | Type | Summary | Epic | Story Points | Status
              """)
            doc.append("\n\n")
            var totalStoryPoints: Double = 0
            for issue in sprint.issues {
                totalStoryPoints += issue.storyPoints ?? 0

                let statusValue = issue.status.uppercased()
                let status: String
                switch statusValue {
                case "TEST":
                    status = "[.blue]#TEST#"
                case "DONE":
                    status = "[.green]#DONE#"
                case "IN PROGRESS":
                    status = "..."
                default:
                    status = statusValue
                }

                let issueTypeValue = issue.issueType
                let issueType: String
                switch issueTypeValue {
                case "Bug":
                    //issueType = "\(issueTypeValue) icon:bug[role=red]"
                    //issueType = "\(issueTypeValue) icon:square-xmark[role=red]"
                    //issueType = "\(issueTypeValue) icon:square-o[role=red]"
                    //issueType = "\(issueTypeValue) icon:square-exclamation[role=red]"
                    //issueType = "\(issueTypeValue) icon:square-ring[role=red]"
                    issueType = "\(issueTypeValue) icon:dot-circle[role=red]"
                default:
                    issueType = issueTypeValue
                }
                
                doc.append(
                  """
                  | \(issue.key)
                  | \(issueType)
                  | \(issue.summary)
                  | \(issue.epicName)
                  | \(issue.storyPointsFormatted)
                  | \(status)
                  """)
                doc.append("\n\n")
            }
            doc.append(
                  """
                  3+|
                  | *Total*
                  | *\(totalStoryPoints)*
                  |
                  """)
            doc.append("\n\n")

            doc.append("|===")
            doc.append("\n\n")
        }
        return doc
    }
    
    func esc(_ txt: String) -> String {
        txt.replacing("[", with: "\\[").replacing("]", with: "\\]")
    }
}
