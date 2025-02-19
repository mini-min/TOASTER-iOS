//
//  SceneDelegate.swift
//  TOASTER-iOS
//
//  Created by 김다예 on 12/30/23.
//

import UIKit

import KakaoSDKAuth
import KakaoSDKCommon

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    let updateAlertManager = UpdateAlertManager()
    
    func checkUpdate(rootViewController: UIViewController) async {
        if let updateStatus = await updateAlertManager.checkUpdateAlertNeeded() {
            updateAlertManager.showUpdateAlert(type: updateStatus,
                                               on: rootViewController)
        }
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let rootViewController = appDelegate.isLogin ? TabBarController() : LoginViewController()
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let navigationController = ToasterNavigationController(rootViewController: rootViewController)
        self.window = UIWindow(windowScene: windowScene)
        self.window?.overrideUserInterfaceStyle = .light
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        Task {
            await checkUpdate(rootViewController: rootViewController)
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if let pasteboardUrl = UIPasteboard.general.url {
            if appDelegate.isLogin {
                guard let rootVC = window?.rootViewController as? ToasterNavigationController else { return }
                let addLinkViewController = AddLinkViewController()
                rootVC.pushViewController(addLinkViewController, animated: true)
                addLinkViewController.embedURL(url: pasteboardUrl.absoluteString)
                                
                if let presentedVC = rootVC.presentedViewController {
                    presentedVC.dismiss(animated: false)
                }
            }
        }
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        UIPasteboard.general.url = nil
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.handleOpenUrl(url: url)
            }
        }
    }
}

