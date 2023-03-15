import Foundation

struct JiraEpicListDTO: Decodable {
    let startAt: Int
    let maxResults: Int
    let total: Int
    let issues: [JiraEpicDTO]
}

struct JiraEpicDTO: Decodable {
    struct Fields: Decodable {
        let summary: String
        let epicName: String
        let epicColor: String
        
        enum CodingKeys: String, CodingKey {
            case summary = "summary"
            case epicName = "customfield_10891"
            case epicColor = "customfield_10893"
        }
    }
    
    let key: String
    let fields: Fields
    var colorName: String = ""
    var colorHex: String = ""
    
    enum CodingKeys: String, CodingKey {
        case key
        case fields
    }
}
