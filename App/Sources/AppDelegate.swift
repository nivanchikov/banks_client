import Swinject
import UIKit
// import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private var container: Container!
    private var assembler: Assembler!

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        FirebaseApp.configure()

        let (assembler, container) = AppDependencies.setup()
        self.container = container
        self.assembler = assembler

        application.openSessions.forEach { session in
            session.container = container
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        connectingSceneSession.container = container

        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>) {}

    func application(_: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let dispatcher = container.resolve(EventDispatcher.self)
        dispatcher?.dispatchEvent(.backgroundFetch, completion: { result in
            switch result {
            case .success:
                completionHandler(.newData)
            case .failure:
                completionHandler(.failed)
            }
        })
    }
}
