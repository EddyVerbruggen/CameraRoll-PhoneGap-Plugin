#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface CameraRoll : CDVPlugin

- (void)count:(CDVInvokedUrlCommand*)command;
- (void)find:(CDVInvokedUrlCommand*)command;

@end