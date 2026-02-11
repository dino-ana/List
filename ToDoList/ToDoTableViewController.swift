//
//  ToDoTableViewController.swift
//  ToDoList
//
//  Created by Diana on 2/11/26.
//

import UIKit
import UserNotifications

class ToDoTableViewController: UITableViewController, ToDoCellDelegate
{
    var todos = [ToDo]()
    private var filteredTodos = [ToDo]()
    let searchController = UISearchController(searchResultsController: nil)
    private let categoryOrder: [ToDoCategory] = [.work, .personal, .completed]
    
    private enum CategoryFilter: Int, CaseIterable {
        case all
        case work
        case personal
        case completed
        
        var title: String {
            switch self {
            case .all:
                return "All"
            case .work:
                return "Work"
            case .personal:
                return "Personal"
            case .completed:
                return "Completed"
            }
        }
        
        var category: ToDoCategory? {
            switch self {
            case .all:
                return nil
            case .work:
                return .work
            case .personal:
                return .personal
            case .completed:
                return .completed
            }
        }
    }
    
    private lazy var categorySegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: CategoryFilter.allCases.map { $0.title })
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(categoryFilterChanged), for: .valueChanged)
        return control
    }()
    
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = editButtonItem
        setupSearchBar()
        setupCategoryFilter()
        if let savedToDos = ToDo.loadToDos() {
            todos = savedToDos
        } else {
            todos = ToDo.loadSampleToDos()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCategoryHeaderLayout()
    }
    
    @IBAction func unwindToToDoList(segue: UIStoryboardSegue) {
        
        guard segue.identifier == "saveUnwind" else { return }
        let sourceViewController = segue.source as! ToDoDetailTableViewController

        if let todo = sourceViewController.todo {
            if let indexOfExistingToDo = todos.firstIndex(of: todo) {
                todos[indexOfExistingToDo] = todo
            } else {
                todos.append(todo)
            }
            updateReminder(for: todo)
        }
        ToDo.saveToDos(todos)
        tableView.reloadData()
    }
    
    @IBSegueAction func editToDo(_ coder: NSCoder, sender: Any?) -> ToDoDetailTableViewController? {
        guard let cell = sender as? UITableViewCell, let indexPath =
                tableView.indexPath(for: cell) else {
            return nil
        }
        let todo = todoForIndexPath(indexPath)
        
        tableView.deselectRow(at: indexPath, animated: true)
        let detailController = ToDoDetailTableViewController(coder: coder)
        detailController?.todo = todo
        return detailController
    }
    
    private func setupSearchBar() {
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = self
        navigationController?.navigationBar.prefersLargeTitles = true
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search title or notes"
        definesPresentationContext = true
    }

    private func setupCategoryFilter() {
        let headerHeight: CGFloat = 44
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: headerHeight))
        categorySegmentedControl.frame = headerView.bounds.insetBy(dx: 16, dy: 6)
        categorySegmentedControl.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        headerView.addSubview(categorySegmentedControl)
        tableView.tableHeaderView = headerView
    }
    
    private func updateCategoryHeaderLayout() {
        guard let headerView = tableView.tableHeaderView else { return }
        if headerView.frame.width != tableView.bounds.width {
            headerView.frame.size.width = tableView.bounds.width
            categorySegmentedControl.frame = headerView.bounds.insetBy(dx: 16, dy: 6)
            tableView.tableHeaderView = headerView
        }
    }
    
    func checkmarkTapped(sender: ToDoCell) {
        if let indexPath = tableView.indexPath(for: sender) {
            let selectedTodo = todoForIndexPath(indexPath)
            guard let todoIndex = todos.firstIndex(of: selectedTodo) else { return }
            var todo = todos[todoIndex]
            todo.isComplete.toggle()
            todos[todoIndex] = todo
            updateReminder(for: todo)
            tableView.reloadData()
        }
        ToDo.saveToDos(todos)
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let selectedTodo = todoForIndexPath(indexPath)
            if let todoIndex = todos.firstIndex(of: selectedTodo) {
                cancelReminder(for: todos[todoIndex])
                todos.remove(at: todoIndex)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            ToDo.saveToDos(todos)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todosForSection(section).count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoCellIdentifier", for: indexPath) as! ToDoCell
        
        let todo = todoForIndexPath(indexPath)
        
        cell.delegate = self
        cell.titleLabel?.text = todo.title
        cell.isCompleteButton.isSelected = todo.isComplete
        cell.tagLabel.text = todo.tagCategory.title
        cell.tagLabel.backgroundColor = todo.tagCategory.color
        cell.tagLabel.textColor = todo.tagCategory.textColor
        applyDueDateHighlight(to: cell, todo: todo)
        
        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if selectedCategoryFilter == .all {
            return categoryOrder.count
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if selectedCategoryFilter == .all {
            return categoryOrder[section].title
        }
        return selectedCategoryFilter.title
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension ToDoTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterContentForSearchText(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        filterContentForSearchText("")
    }
}

extension ToDoTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text ?? "")
    }
}

private extension ToDoTableViewController {
    private var selectedCategoryFilter: CategoryFilter {
        return CategoryFilter(rawValue: categorySegmentedControl.selectedSegmentIndex) ?? .all
    }
    
    func filterContentForSearchText(_ searchText: String) {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let terms = trimmed.split(separator: " ").map(String.init)
        
        if terms.isEmpty {
            filteredTodos = []
        } else {
            filteredTodos = todos.filter { todo in
                let notes = todo.notes ?? ""
                let haystack = "\(todo.title) \(notes)".lowercased()
                return terms.allSatisfy { haystack.contains($0) }
            }
        }
        tableView.reloadData()
    }
    
    func todosForSection(_ section: Int) -> [ToDo] {
        let baseTodos = isFiltering ? filteredTodos : todos
        if selectedCategoryFilter == .all {
            let category = categoryOrder[section]
            return baseTodos.filter { $0.tagCategory == category }
        }
        if let category = selectedCategoryFilter.category {
            return baseTodos.filter { $0.tagCategory == category }
        }
        return baseTodos
    }
    
    func todoForIndexPath(_ indexPath: IndexPath) -> ToDo {
        return todosForSection(indexPath.section)[indexPath.row]
    }
    
    @objc func categoryFilterChanged() {
        tableView.reloadData()
    }

    func applyDueDateHighlight(to cell: ToDoCell, todo: ToDo) {
        cell.contentView.backgroundColor = .clear
        cell.titleLabel.textColor = .label
        
        guard !todo.isComplete else { return }
        
        let now = Date()
        if todo.dueDate < now {
            cell.contentView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
            cell.titleLabel.textColor = .systemRed
        } else if todo.dueDate < now.addingTimeInterval(24 * 60 * 60) {
            cell.contentView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
            cell.titleLabel.textColor = .systemOrange
        }
    }

    func updateReminder(for todo: ToDo) {
        if todo.shouldRemind && !todo.isComplete {
            scheduleReminder(for: todo)
        } else {
            cancelReminder(for: todo)
        }
    }

    func scheduleReminder(for todo: ToDo) {
        guard todo.shouldRemind,
              !todo.isComplete,
              let notificationId = todo.notificationId,
              todo.dueDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "To-Do Reminder"
        content.body = todo.title
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: todo.dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder(for todo: ToDo) {
        guard let notificationId = todo.notificationId else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
    }
}
