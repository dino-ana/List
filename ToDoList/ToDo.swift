//
//  ToDo.swift
//  ToDoList
//
//  Created by Diana on 2/11/26.
//

import Foundation
import UIKit

enum ToDoCategory: String, Codable, CaseIterable {
    case work
    case personal
    case completed
    
    var title: String {
        switch self {
        case .work:
            return "Work"
        case .personal:
            return "Personal"
        case .completed:
            return "Completed"
        }
    }
    
    var color: UIColor {
        switch self {
        case .work:
            return UIColor(red: 0.96, green: 0.77, blue: 0.75, alpha: 1.0)
        case .personal:
            return UIColor(red: 0.80, green: 0.90, blue: 0.98, alpha: 1.0)
        case .completed:
            return UIColor(red: 0.80, green: 0.94, blue: 0.84, alpha: 1.0)
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .completed:
            return UIColor(red: 0.16, green: 0.46, blue: 0.27, alpha: 1.0)
        case .work:
            return UIColor(red: 0.45, green: 0.20, blue: 0.18, alpha: 1.0)
        case .personal:
            return UIColor(red: 0.16, green: 0.30, blue: 0.52, alpha: 1.0)
        }
    }
}

struct ToDo: Equatable, Codable {
    var id = UUID()
    var title: String
    var isComplete: Bool
    var category: ToDoCategory
    var dueDate: Date
    var notes: String?
    var shouldRemind: Bool = false
    var notificationId: String?
    
    static let documentsDirectory = FileManager.default.urls(for: .documentDirectory,
       in: .userDomainMask).first!
    
    static let archiveURL = documentsDirectory.appendingPathComponent("todos").appendingPathExtension("plist")
    
    static func ==(lhs: ToDo, rhs: ToDo) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func loadToDos() -> [ToDo]?  {
        guard let codedToDos = try? Data(contentsOf: archiveURL) else { return nil }
        
        let propertyListDecoder = PropertyListDecoder()
        return try? propertyListDecoder.decode(Array<ToDo>.self,
           from: codedToDos)
    }
    
    static func saveToDos(_ todos: [ToDo]) {
        let propertyListEncoder = PropertyListEncoder()
        let codedToDos = try? propertyListEncoder.encode(todos)
        try? codedToDos?.write(to: archiveURL, options: .noFileProtection)
    }
    
    static func loadSampleToDos() -> [ToDo] {
        let todo1 = ToDo(title: "ToDo One", isComplete: false, category: .work,
           dueDate: Date(), notes: "Notes 1")
        let todo2 = ToDo(title: "ToDo Two", isComplete: false, category: .personal,
           dueDate: Date(), notes: "Notes 2")
        let todo3 = ToDo(title: "ToDo Three", isComplete: false, category: .work,
           dueDate: Date(), notes: "Notes 3")
    
        return [todo1, todo2, todo3]
    }
    
    static let dueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var tagCategory: ToDoCategory {
        return isComplete ? .completed : category
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case isComplete
        case category
        case dueDate
        case notes
        case shouldRemind
        case notificationId
    }
    
    init(id: UUID = UUID(), title: String, isComplete: Bool, category: ToDoCategory, dueDate: Date, notes: String?) {
        self.id = id
        self.title = title
        self.isComplete = isComplete
        self.category = category
        self.dueDate = dueDate
        self.notes = notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        isComplete = try container.decode(Bool.self, forKey: .isComplete)
        category = try container.decodeIfPresent(ToDoCategory.self, forKey: .category) ?? .personal
        dueDate = try container.decode(Date.self, forKey: .dueDate)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        shouldRemind = try container.decodeIfPresent(Bool.self, forKey: .shouldRemind) ?? false
        notificationId = try container.decodeIfPresent(String.self, forKey: .notificationId)
    }
}
