//
//  SceneDelegate.m
//  AIChat
//
//  Created by JiangYing on 2025/10/3.
//

#import "SceneDelegate.h"
#import "JYMacro.h"
#import "JYChatViewController.h"

@interface SceneDelegate ()

@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *windowScene = JY_SAFE_CAST(scene, UIWindowScene);
    if (windowScene != nil) {
        self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
        UIApplication.sharedApplication.delegate.window = self.window;
        UIStoryboard *launchStoryboard = [UIStoryboard storyboardWithName:@"LaunchScreen" bundle:nil];
        UIViewController *launchVC = [launchStoryboard instantiateInitialViewController];
        self.window.rootViewController = launchVC;
        [self.window makeKeyAndVisible];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            JYChatViewController *chatVC = [[JYChatViewController alloc] init];
            UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:chatVC];
            self.window.rootViewController = navVC;
        });
    }
}


- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
}


- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
}


@end
