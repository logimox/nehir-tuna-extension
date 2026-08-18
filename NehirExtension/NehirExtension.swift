import Foundation
import TunaKit

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
        minTunaKit: "1.14.0"
      ),
      catalogs: [
        CatalogDeclaration(
          id: "nehir",
          type: NehirCatalog.self,
          name: "Nehir Windows & Workspaces",
          enabledByDefault: true
        )
      ],
      actionCatalogs: [
        ActionCatalogDeclaration(
          id: "nehir.actions",
          type: NehirActionsCatalog.self,
          name: "Nehir Actions"
        )
      ]
    )
  }
}
