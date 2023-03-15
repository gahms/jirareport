import Foundation
import KeychainSwift

enum JiraServiceError: Error {
    case missingToken
}

class JiraService {
    let networkService: NetworkService
    let keychain: KeychainSwift = .init()
    var token: String? = nil
    
    var epics: [String: JiraEpicDTO] = [:]
    var sprints: [JiraSprintDTO] = []
    
    init(baseURL: String) {
        networkService = .init(baseURL: baseURL)
    }
    
    func epicForJira(_ dto: JiraIssueDTO?) -> JiraEpicDTO? {
        guard let dto else { return nil }
        guard let epicLink = dto.fields.epicLink else { return nil }
        return epics[epicLink]
    }
    
    let jiraColorNames: [String: String] = [
        "ghx-label-1": "dark_grey",
        "ghx-label-2": "dark_yellow",
        "ghx-label-3": "yellow",
        "ghx-label-4": "dark_blue",
        "ghx-label-5": "dark_teal",
        "ghx-label-6": "green",
        "ghx-label-7": "purple",
        "ghx-label-8": "dark_purple",
        "ghx-label-9": "orange",
        "ghx-label-10": "blue",
        "ghx-label-11": "teal",
        "ghx-label-12": "grey",
        "ghx-label-13": "dark_green",
        "ghx-label-14": "dark_orange"
    ]

    let jiraColorValues: [String: String] = [
        "ghx-label-1": "0x8d542e",
        "ghx-label-2": "0xff8b00",
        "ghx-label-3": "0xffab01",
        "ghx-label-4": "0x0052cc",
        "ghx-label-5": "0x505f79",
        "ghx-label-6": "0x5fa321",
        "ghx-label-7": "0xcd4288",
        "ghx-label-8": "0x5143aa",
        "ghx-label-9": "0xff8f73",
        "ghx-label-10": "0x2584ff",
        "ghx-label-11": "0x018da6",
        "ghx-label-12": "0x6b778c",
        "ghx-label-13": "0x03875a",
        "ghx-label-14": "0xde350a",
    ]
    
    func loadJiraToken() throws {
        token = keychain.get("jira")
        if token == nil {
            throw JiraServiceError.missingToken
        }
        networkService.authToken = token
    }
    
    private func translateColor(_ epic: JiraEpicDTO) -> JiraEpicDTO {
        var e = epic
        e.colorName = jiraColorNames[epic.fields.epicColor] ?? "unknown"
        e.colorHex = jiraColorValues[epic.fields.epicColor] ?? "0x00ee00"
        
        return e
    }
    
    private func isSprintBefore(_ a: JiraSprintDTO, _ b: JiraSprintDTO) -> Bool {
        if let ad = a.startDate, let bd = b.startDate {
            if ad == bd {
                return a.id < b.id
            }
            else {
                return ad < bd
            }
        }
        else if let _ = a.startDate {
            return true
        }
        else if let _ = b.startDate {
            return false
        }
        else {
            return a.id < b.id
        }
    }
    
    func fetchProjectEpics(project: String) async
    -> Bool {
        let result = await networkService.getProjectEpics(project: project)
        switch result {
        case .success(let epicsList):
            epics = Dictionary(uniqueKeysWithValues: epicsList.issues.map {
                ($0.key, translateColor($0))
            })
            return true
        case .failure(let error):
            print("ERROR: \(error)")
            return false
        }
    }
    
    func fetchBoardSprints(board: String) async -> Bool {
        var sprints: [JiraSprintDTO] = []
        var done: Bool = false
        var startAt: Int = 0
        while !done {
            let results = await networkService.getSprintsForBoard(
                board, startAt: startAt)
            switch results {
            case .success(let sprintList):
                sprints.append(contentsOf: sprintList.values)
                if sprintList.isLast {
                    done = true
                }
                startAt += sprintList.maxResults
                
            case .failure(let error):
                print("ERROR: \(error)")
                return false
            }
        }
        
        self.sprints = sprints
        // Actually recieved in the right order
        // self.sprints = sprints.sorted(by: isSprintBefore(_:_:))
        
        return true
    }

    func fetchIssues(board: String, sprint: Int) async -> [JiraIssueDTO] {
        var issues: [JiraIssueDTO] = []
        var done: Bool = false
        var startAt: Int = 0
        while !done {
            let results = await networkService.getIssuesForBoard(
                board, sprint: sprint, startAt: startAt)
            switch results {
            case .success(let issueList):
                issues.append(contentsOf: issueList.issues)
                if startAt + issueList.maxResults >= issueList.total {
                    done = true
                }
                startAt += issueList.maxResults
                
            case .failure(let error):
                print("ERROR: \(error)")
                return []
            }
        }

        return issues
    }

    func fetchIssues(sprints: [Int]) async -> [JiraIssueDTO] {
        var issues: [JiraIssueDTO] = []
        var done: Bool = false
        var startAt: Int = 0
        while !done {
            let results = await networkService.getIssues(
                sprints: sprints, startAt: startAt)
            switch results {
            case .success(let issueList):
                issues.append(contentsOf: issueList.issues)
                if startAt + issueList.maxResults >= issueList.total {
                    done = true
                }
                startAt += issueList.maxResults
                
            case .failure(let error):
                print("ERROR: \(error)")
                return []
            }
        }
        
        return issues
    }

    func fetchJira(key: String) async -> Result<JiraIssueDTO, NetworkServiceError> {
        return await networkService.getIssueDetails(key: key)
    }
}
