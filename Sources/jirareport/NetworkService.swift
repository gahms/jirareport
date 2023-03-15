import Foundation

enum NetworkServiceError: Error {
    case unknown
    case errorResponse(statusCode: Int, response: String?)
    case badResponse(statusCode: Int?, error: Error)
    case decodingFailed
    case encodingFailed
    case noResponseBody
}

var standardError = FileHandle.standardError

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        let data = Data(string.utf8)
        self.write(data)
    }
}

func progressLog(_ message: String) {
    print(message, terminator: "", to: &standardError)
}

class NetworkService {
    var baseURL: String
    var apiBaseURL: String {
        "\(baseURL)/api/latest/"
    }
    var agileBaseURL: String {
        "\(baseURL)/agile/1.0/"
    }
    
    var verbose: Bool = false
    var quiet: Bool = false
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    private var urlSession: URLSession { URLSession.shared }
    private lazy var jsonDecoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .custom(FlexibleJSONDateDecoder.decode)
        return dec
    }()
    private lazy var jsonEncoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()
    
    private lazy var birthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter
    }()
    
    private lazy var userAgent: String = {
        return "JiraReportCmd/1 macOS/12"
    }()
    
    var authToken: String?
    
    enum HTTPMethod: String {
        case options = "OPTIONS"
        case get     = "GET"
        case head    = "HEAD"
        case post    = "POST"
        case put     = "PUT"
        case patch   = "PATCH"
        case delete  = "DELETE"
        case trace   = "TRACE"
        case connect = "CONNECT"
    }
    
    private struct NoParameters: Encodable {
        static let value: NoParameters? = nil
    }
        
    func getIssueDetails(key: String) async -> Result<JiraIssueDTO, NetworkServiceError> {
        return await request(
            endpoint: "issue/\(key)",
            method: .get,
            parameters: NoParameters.value,
            token: authToken
        )
    }
    
    func getProjectEpics(project: String) async
    -> Result<JiraEpicListDTO, NetworkServiceError> {
        return await request(
            endpoint: "search?expand=names&jql=project%3D"
            + "\(project)%20"
            + "AND%20issuetype%3DEpic%20"
            + "AND%20status%20NOT%20IN%20(Done)"
            + "&fields=key,summary,customfield_10891,customfield_10893",
            method: .get,
            parameters: NoParameters.value,
            token: authToken
        )
    }
    
    func getSprintsForBoard(_ board: String, startAt: Int) async
    -> Result<JiraSprintListDTO, NetworkServiceError> {
        return await request(
            base: agileBaseURL,
            endpoint: "board/\(board)/sprint?startAt=\(startAt)",
            method: .get,
            parameters: NoParameters.value,
            token: authToken
        )
    }
    
    func getIssuesForBoard(_ board: String, sprint: Int, startAt: Int) async
    -> Result<JiraIssuesListDTO, NetworkServiceError> {
        return await request(
            base: agileBaseURL,
            endpoint: "board/\(board)/sprint/\(sprint)/issue?startAt=\(startAt)",
            method: .get,
            parameters: NoParameters.value,
            token: authToken
        )
    }

    func getIssues(sprints: [Int], startAt: Int) async
    -> Result<JiraIssuesListDTO, NetworkServiceError> {
        return await request(
            endpoint: "search?expand=names&jql="
            + "Sprint%20IN%20(\(sprints.map { "\($0)" }.joined(separator: ", "))"
            + "&fields=key,summary,status,issuetype,customfield_10890,customfield_11890,issuetype,customfield_10012",
            method: .get,
            parameters: NoParameters.value,
            token: authToken
        )
    }

    func request<ResponseType: Decodable, RequestBodyType: Encodable>(
        base: String? = nil,
        endpoint: String,
        method: HTTPMethod,
        parameters: RequestBodyType?,
        token: String?,
        extraHeaders: [String: String] = [:],
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: Int = #line) async -> Result<ResponseType, NetworkServiceError> {
            
            let baseURL = base ?? self.apiBaseURL
            guard let url = URL(string: baseURL + endpoint) else {
                fatalError("Invalid URL: \(baseURL + endpoint)")
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            for header in extraHeaders {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
            
            let bodyData: Data?
            if let parameters = parameters {
                bodyData = try? jsonEncoder.encode(parameters)
                guard let bodyData = bodyData else {
                    return .failure(.encodingFailed)
                }
                request.httpBody = bodyData
            }
            else {
                bodyData = nil
            }
            
            if let token = token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            if verbose {
                if let bodyData = bodyData {
                    let sbody = String(data: bodyData, encoding: .utf8) ?? ""
                    
                    print("\(method.rawValue) \(url.absoluteString)\n\(sbody)")
                }
                else {
                    print("\(method.rawValue) \(url.absoluteString)")
                }
            }
            
            if !quiet {
                progressLog(".")
            }
            
            return await withCheckedContinuation {
                [jsonDecoder] (continuation: CheckedContinuation
                               <Result<ResponseType, NetworkServiceError>, Never>) in
                let task = urlSession.dataTask(with: request) { data, response, error in
                    if let error = error {
                        let response = response as? HTTPURLResponse
                        let statusCode = response?.statusCode
                        continuation.resume(returning: .failure(
                            .badResponse(
                                statusCode: statusCode,
                                error: error)))
                        
                        print("ERROR: \(endpoint) statusCode: \(statusCode.orNil): \(error)")
                        return
                    }
                    guard let response = response as? HTTPURLResponse else {
                        continuation.resume(returning: .failure(.unknown))
                        print("INTERNAL ERROR! Response is not a HTTPURLResponse?")
                        return
                    }
                    if !(200...299).contains(response.statusCode) {
                        let responseString: String
                        if let data {
                            responseString = String(data: data, encoding: .utf8) ?? "<invalid>"
                        }
                        else {
                            responseString = ""
                        }
                        
                        print("ERROR: \(endpoint) statusCode: \(response.statusCode): response body: \(responseString)")
                        
                        continuation.resume(returning: .failure(
                            .errorResponse(
                                statusCode: response.statusCode,
                                response: responseString)))
                        
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(returning: .failure(.noResponseBody))
                        return
                    }
                    
                    do {
                        /*
                        let sdata = String(data: data, encoding: .utf8) ?? "<invalid>"
                        */
                        let result = try jsonDecoder.decode(ResponseType.self, from: data)
                        
                        continuation.resume(returning: .success(result))
                    }
                    catch {
                        let sdata = String(data: data, encoding: .utf8) ?? "<invalid>"
                        print("ERROR: \(endpoint) Error decoding: \(error), server response: \(sdata)")
                        continuation.resume(returning: .failure(.decodingFailed))
                    }
                }
                
                task.resume()
            }
        }
    
    private func decode<T>(_ type: T.Type, from data: Data?) -> (T?, String) where T: Decodable {
        let errorResponse: T?
        let sdata: String
        if let data = data {
            sdata = String(data: data, encoding: .utf8) ?? "<invalid>"
            if T.self == String.self {
                return ((sdata as! T), sdata)
            }
            do {
                errorResponse = try jsonDecoder.decode(type, from: data)
            }
            catch {
                errorResponse = nil
            }
        }
        else {
            sdata = "<empty>"
            errorResponse = nil
        }
        
        return (errorResponse, sdata)
    }
}
