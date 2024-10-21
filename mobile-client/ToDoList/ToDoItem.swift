
import SwiftData
import SwiftUI

struct ToDoItem: Identifiable, Codable, Equatable {
    var id: Int
    var title: String
    var deadline: String
    var status: String
    var tags: [String]
    var createdAt: String
    var updatedAt: String
}

/*
 @Model
 final class ToDoItem: Identifiable {

     @Attribute(.unique) var id: Int
     var data: ToDoItemData

     init(id: Int, data: ToDoItemData) {
         self.id = id
         self.data = data
     }
 }
 */
/*
 @Model
 final class ToDoItem: Identifiable, Codable {
     // CodingKeys enum defines the keys for encoding and decoding
     enum CodingKeys: String, CodingKey {
         case id
         case title
         case deadline
         case createdAt
         case updatedAt
     }

     var id: Int
     var title: String
     var deadline: String
     var createdAt: String
     var updatedAt: String

     init(id: Int, title: String, deadline: String, createdAt: String, updatedAt: String) {
         self.id = id
         self.title = title
         self.deadline = deadline
         self.createdAt = createdAt
         self.updatedAt = updatedAt
     }

     // Decoding (Decodable)
     required convenience init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         let id = try container.decode(Int.self, forKey: .id)
         let title = try container.decode(String.self, forKey: .title)
         let deadline = try container.decode(String.self, forKey: .deadline)
         let createdAt = try container.decode(String.self, forKey: .createdAt)
         let updatedAt = try container.decode(String.self, forKey: .updatedAt)
         self.init(id: id, title: title, deadline: deadline, createdAt: createdAt, updatedAt: updatedAt)
     }

     // Encoding (Encodable)
     func encode(to encoder: Encoder) throws {
         var container = encoder.container(keyedBy: CodingKeys.self)
         try container.encode(id, forKey: .id)
         try container.encode(title, forKey: .title)
         try container.encode(deadline, forKey: .deadline)
         try container.encode(createdAt, forKey: .createdAt)
         try container.encode(updatedAt, forKey: .updatedAt)
     }
 }
 */
