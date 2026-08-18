import Foundation
import TunaKit

extension TypeID {
  static let nehirWindow = TypeID("com.logimox.nehir.window")
  static let nehirWorkspace = TypeID("com.logimox.nehir.workspace")
}

@objc(NehirExtension)
public final class NehirExtension: Extension {
  public override var declaration: ExtensionDeclaration? {
    ExtensionDeclaration(
      metadata: ExtensionMetadata(
        displayName: "Nehir",
        author: "Andreas F",
        description: "Search and control Nehir workspaces and windows.",
        iconName: "rectangle.3.group"
      ),
      compatibility: ExtensionDeclarationCompatibility(
        minTuna: "0.80",
        minTunaKit: "1.19.0"
      ),
      catalogs: [
        CatalogDeclaration(
          id: "nehir.windows",
          type: NehirCatalog.self,
          name: "Nehir Windows",
          enabledByDefault: true
        ),
        CatalogDeclaration(
          id: "nehir.workspaces",
          type: NehirCatalog.self,
          name: "Nehir Workspaces",
          enabledByDefault: true
        )
      ],
      actionCatalogs: [
        ActionCatalogDeclaration(
          id: "nehir.actions",
          type: NehirActionsCatalog.self,
          name: "Nehir Actions"
        )
      ],
      typeRegistrations: [
        TypeRegistrationDefinition(
          typeID: .nehirWindow,
          displayName: "Nehir Window",
          inheritsFrom: [.entity]
        ),
        TypeRegistrationDefinition(
          typeID: .nehirWorkspace,
          displayName: "Nehir Workspace",
          inheritsFrom: [.entity]
        )
      ],
      defaultActionRankings: [
        DefaultActionRankingDefinition(
          typeID: .nehirWorkspace,
          actions: [
            ActionReference(catalogIdentifier: "nehir.actions", actionID: "switch-workspace")
          ]
        ),
        DefaultActionRankingDefinition(
          typeID: .nehirWindow,
          actions: [
            ActionReference(catalogIdentifier: "nehir.actions", actionID: "move-window-to-workspace")
          ]
        )
      ]
    )
  }
}
