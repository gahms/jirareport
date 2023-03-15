import Foundation

struct JiraEpicViewModel {
    let key: String
    let epicName: String
    let summary: String
    let color: JiraColorViewModel
}

extension JiraEpicViewModel {
    init?(_ dto: JiraEpicDTO?) {
        guard let dto else { return nil }
        key = dto.key
        epicName = dto.fields.epicName
        summary = dto.fields.summary
        color = JiraColorViewModel(name: dto.colorName, hex: dto.colorHex)
    }
}
