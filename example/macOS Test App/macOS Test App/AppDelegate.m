//
//  AppDelegate.m
//  macOS Test App
//
//  Created by Jason Cox on 1/19/25.
//

#import "AppDelegate.h"

@interface AppDelegate ()


@end

@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    // libcurl - see http://curl.haxx.se/libcurl/
    curl_global_init(0L);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    // libcurl cleanup
    curl_global_cleanup();
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

@end
