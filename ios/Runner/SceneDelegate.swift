import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    DispatchQueue.main.async { [weak self] in
      guard let controller = self?.window?.rootViewController as? FlutterViewController else {
        return
      }
      WidgetBridge.configure(binaryMessenger: controller.binaryMessenger)
    }
  }

  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    if let url = URLContexts.first?.url {
      WidgetBridge.handleURL(url)
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
