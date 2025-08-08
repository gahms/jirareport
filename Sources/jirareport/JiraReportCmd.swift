import Foundation
import ArgumentParser

@main
struct JiraReportCmd: AsyncParsableCommand {
    @Flag(name: [.customLong("verbose"), .customShort("v")], help: "Show logs, information and non blocking messages.")
    var verbose = false
    
    @Option(name: .long, help: "Jira API Personal Access Token")
    var token: String?
    
    @Option(name: .long, help: "Jira API Personal Access Token")
    var saveToken: String?

    @Flag(name: .long, help: "Delete saved Jira API Personal Access Token")
    var forgetToken: Bool = false
    
    @Option(name: .long, help: "Jira API base URL")
    var baseURL: String
    
    @Option(name: .long, help: "Project key")
    var projectKey: String
    
    @Option(name: .long, help: "Board number")
    var boardNumber: String
    
    @Option(name: .long, help: "First sprint to show")
    var firstSprint: String?
    
    @Option(name: .long, help: "Document title")
    var title: String?
    
    @Option(name: .long, help: "Key column width in percent")
    var keyColWidth: Int = 11

    @Option(name: .long, help: "Page break before specified sprints")
    var pageBreakBefore: String?

    enum OutputFormat: String, ExpressibleByArgument {
        case asciidoc
        case text
    }
    
    @Option(name: .long, help: "Output format")
    var outputFormat: OutputFormat

    func run() async throws {
        if forgetToken {
            let service = JiraService(baseURL: "")
            service.forgetJiraToken()
            throw ExitCode.success
        }
        
        let service = JiraService(baseURL: baseURL)
        
        if let saveToken {
            service.setJiraToken(saveToken, save: true)
        }
        else if let token {
            service.setJiraToken(token, save: false)
        }
        else {
            do {
                try service.loadJiraToken()
            }
            catch JiraServiceError.missingToken {
                errorLog("""
                  Missing Jira token.
                  Go to Jira -> Your profile -> Personal Access Tokens -> Create token
                  invoke this command again with
                    --save-token <token>
                  or
                    --token <token>
                """)
                throw ExitCode.failure
            }
        }
        
        guard await service.fetchProjectEpics(project: projectKey) else {
            return
        }

        /*
        let epics = service.epics.values
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
        for epic in epics {
            print("\(epic.key): \(epic.fields.epicName) [\(epic.colorName)/\(epic.colorHex)]")
        }
        // */

        //*
        guard await service.fetchBoardSprints(board: boardNumber) else {
            return
        }
        
        let firstSprintIndex = service.sprints
            .firstIndex { $0.name == firstSprint } ?? 0
        let sprints = service.sprints[firstSprintIndex...]
        
        var sprintVMs: [JiraSprintViewModel] = []
        let ignoredStates = [ "To Do", "In Progress" ]
        for sprint in sprints {
            let issues = await service.fetchIssues(board: boardNumber, sprint: sprint.id)
                .filter {
                    !(ignoredStates.contains($0.fields.status.name) && sprint.state == .closed)
                }
            let issueVMs = issues.map {
                JiraIssueViewModel($0, epicDTO: service.epicForJira($0))
            }
            sprintVMs.append(.init(sprint, issues: issueVMs))
        }

        let output: String
        switch outputFormat {
        case .asciidoc:
            let f = AsciiDocOutput()
            f.title = title
            f.keyColWidth = keyColWidth
            f.pageBreakBefore = pageBreakBefore
            output = f.format(sprints: sprintVMs)
            
        case .text:
            let f = TxtOutput()
            output = f.format(sprints: sprintVMs)
        }
        print(output)
        
        throw ExitCode.success
    }
}
