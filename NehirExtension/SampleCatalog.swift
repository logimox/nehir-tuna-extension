import Foundation
import TunaKit

@MainActor
final class NehirCatalog: NSObject, Catalog {
  let identifier: String
  let name: String
  private(set) var objects: [CatalogItem] = []

  required init(definition: CatalogDefinition) {
    identifier = definition.identifier
    name = definition.name
    super.init()
  }

  func scan() async {
    do {
      switch identifier {
      case "nehir.workspaces":
        let workspaces = try NehirCLI.run(["query", "workspaces", "--format", "json"])
        objects = try NehirItemFactory.makeWorkspaceItems(workspacesJSON: workspaces)
      default:
        let windows = try NehirCLI.run(["query", "windows", "--format", "json"])
        objects = try NehirItemFactory.makeWindowItems(windowsJSON: windows)
      }
    } catch {
      objects = [CatalogItem(id: "ipc-unavailable", title: "Nehir IPC is unavailable", type: .entity)]
    }
    reportScanFinished()
  }
}

/// Runs the official Nehir CLI, which safely reads its local IPC authorization.
enum NehirCLI {
  static func run(_ arguments: [String]) throws -> Data {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/nehirctl")
    process.arguments = arguments
    let output = Pipe()
    let errors = Pipe()
    process.standardOutput = output
    process.standardError = errors
    try process.run()
    process.waitUntilExit()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    guard process.terminationStatus == 0 else {
      let error = String(data: errors.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Nehir command failed"
      throw NSError(domain: "Nehir", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: error])
    }
    return data
  }
}

final class NehirWindowItem: CatalogEntity, @unchecked Sendable {
  let windowID: String
  let detailText: String

  init(windowID: String, title: String, detail: String) {
    self.windowID = windowID
    self.detailText = detail
    super.init(id: "window:\(windowID)", title: title, path: nil)
    typeID = .nehirWindow
  }

  override var detail: String? { detailText }
}

final class NehirWorkspaceItem: CatalogEntity, @unchecked Sendable {
  /// Nehir commands switch by numeric workspace number, not its persistent UUID.
  let workspaceNumber: String
  let detailText: String

  init(workspaceID: String, workspaceNumber: String, title: String, detail: String) {
    self.workspaceNumber = workspaceNumber
    self.detailText = detail
    super.init(id: "workspace:\(workspaceID)", title: title, path: nil)
    typeID = .nehirWorkspace
  }

  override var detail: String? { detailText }
}

final class NehirActionsCatalog: NSObject, ActionCatalog {
  let identifier: String
  let name: String
  private(set) lazy var actions: [CatalogAction] = [focusWindow, navigateToWindow, switchWorkspace, moveFocusedWindowToWorkspace]

  required init(definition: ActionCatalogDefinition) {
    identifier = definition.identifier
    name = definition.name
    super.init()
  }

  private lazy var focusWindow: CatalogAction = windowAction(id: "focus-window", title: "Focus Nehir Window", operation: "focus")
  private lazy var navigateToWindow: CatalogAction = windowAction(id: "navigate-to-window", title: "Navigate to Nehir Window", operation: "navigate")

  private func windowAction(id: String, title: String, operation: String) -> CatalogAction {
    let action = PredicateAwareAction(id: id, title: title) { subject, _ in
      guard let window = subject as? NehirWindowItem else { return .failure("Select a Nehir window.") }
      do {
        _ = try NehirCLI.run(["window", operation, window.windowID])
        return .success
      } catch { return .failure(error.localizedDescription) }
    }
    action.subjectPredicate = { $0 is NehirWindowItem }
    action.systemSymbolName = "macwindow"
    return action
  }

  private lazy var switchWorkspace: CatalogAction = workspaceAction(
    id: "switch-workspace",
    title: "Switch to Nehir Workspace",
    symbol: "rectangle.3.group",
    command: "switch-workspace"
  )

  private lazy var moveFocusedWindowToWorkspace: CatalogAction = {
    let action = PredicateAwareAction(
      id: "move-window-to-workspace",
      title: "Move Nehir Window to Workspace"
    ) { window, target in
      guard let window = window as? NehirWindowItem else { return .failure("Select a Nehir window.") }
      guard let workspace = target as? NehirWorkspaceItem else { return .failure("Choose a destination Nehir workspace.") }
      do {
        // Nehir's IPC has no move-by-window-ID action. Focus the explicitly
        // selected window through IPC, then move that focused window.
        _ = try NehirCLI.run(["window", "focus", window.windowID])
        _ = try NehirCLI.run(["command", "move-to-workspace", workspace.workspaceNumber])
        return .success
      } catch { return .failure(error.localizedDescription) }
    }
    action.subjectPredicate = { $0 is NehirWindowItem }
    action.targetPredicate = { $0 is NehirWorkspaceItem }
    action.systemSymbolName = "rectangle.portrait.and.arrow.forward"
    return action
  }()

  private func workspaceAction(id: String, title: String, symbol: String, command: String) -> CatalogAction {
    let action = PredicateAwareAction(id: id, title: title) { subject, _ in
      guard let workspace = subject as? NehirWorkspaceItem else { return .failure("Select a Nehir workspace.") }
      do {
        _ = try NehirCLI.run(["command", command, workspace.workspaceNumber])
        return .success
      } catch { return .failure(error.localizedDescription) }
    }
    action.subjectPredicate = { $0 is NehirWorkspaceItem }
    action.systemSymbolName = symbol
    return action
  }
}

private enum NehirItemFactory {
  static func makeWindowItems(windowsJSON: Data) throws -> [CatalogItem] {
    let windows = try JSONSerialization.jsonObject(with: windowsJSON) as? [String: Any] ?? [:]
    return payloadRows(windows).compactMap { row in
      guard let id = string(row["id"]) else { return nil }
      let app = objectString(row["app"], key: "name") ?? "Unknown App"
      let title = string(row["title"]) ?? "Untitled"
      let workspace = objectString(row["workspace"], key: "displayName") ?? ""
      return NehirWindowItem(
        windowID: id,
        title: "\(app): \(title)",
        detail: workspace.isEmpty ? "Nehir window" : "Workspace \(workspace)"
      )
    }
  }

  static func makeWorkspaceItems(workspacesJSON: Data) throws -> [CatalogItem] {
    let workspaces = try JSONSerialization.jsonObject(with: workspacesJSON) as? [String: Any] ?? [:]
    return payloadRows(workspaces).compactMap { row in
      guard let id = string(row["id"]) else { return nil }
      let name = string(row["displayName"]) ?? string(row["rawName"]) ?? id
      let number = string(row["number"]) ?? name
      let current = bool(row["isCurrent"]) == true
      let count = objectNumber(row["counts"], key: "total") ?? 0
      let title = "Nehir Workspace \(name)"
      let detail = "\(count) window\(count == 1 ? "" : "s")\(current ? " · Current" : "")"
      return NehirWorkspaceItem(
        workspaceID: id,
        workspaceNumber: number,
        title: title,
        detail: detail
      )
    }
  }

  private static func payloadRows(_ response: [String: Any]) -> [[String: Any]] {
    let result = response["result"] as? [String: Any] ?? [:]
    let payload = result["payload"]
    if let rows = payload as? [[String: Any]] { return rows }
    if let dictionary = payload as? [String: Any] {
      for value in dictionary.values {
        if let rows = value as? [[String: Any]] { return rows }
      }
    }
    return []
  }

  private static func objectString(_ value: Any?, key: String) -> String? {
    guard let object = value as? [String: Any] else { return nil }
    return string(object[key])
  }

  private static func objectNumber(_ value: Any?, key: String) -> Int? {
    guard let object = value as? [String: Any], let number = object[key] as? NSNumber else { return nil }
    return number.intValue
  }

  private static func bool(_ value: Any?) -> Bool? {
    (value as? NSNumber)?.boolValue
  }

  private static func string(_ value: Any?) -> String? {
    if let value = value as? String { return value }
    if let value = value as? NSNumber { return value.stringValue }
    return nil
  }
}
