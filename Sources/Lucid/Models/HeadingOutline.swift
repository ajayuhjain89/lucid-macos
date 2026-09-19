import Foundation

public struct HeadingItem: Identifiable, Hashable, Codable {
    public var id: String
    public var level: Int
    public var text: String

    public init(id: String, level: Int, text: String) {
        self.id = id
        self.level = level
        self.text = text
    }
}
