import Foundation
import ArgumentParser

@main
struct JiraReportCmd: AsyncParsableCommand {
    @Flag(name: [.customLong("verbose"), .customShort("v")], help: "Show logs, information and non blocking messages.")
    var verbose = false
    
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
    
    enum OutputFormat: String, ExpressibleByArgument {
        case asciidoc
        case text
    }
    
    @Option(name: .long, help: "Output format")
    var outputFormat: OutputFormat

    func run() async throws {
        let service = JiraService(baseURL: baseURL)
        try service.loadJiraToken()
                
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
        for sprint in sprints {
            let issues = await service.fetchIssues(board: boardNumber, sprint: sprint.id)
                .filter {
                    !($0.fields.status.name == "To Do" && sprint.state == .closed)
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
            output = f.format(sprints: sprintVMs)
            
        case .text:
            let f = TxtOutput()
            output = f.format(sprints: sprintVMs)
        }
        print(output)
        
        throw ExitCode.success
    }
}
