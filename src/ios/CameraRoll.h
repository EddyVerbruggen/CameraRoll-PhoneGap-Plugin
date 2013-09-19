#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface CameraRoll : CDVPlugin

- (void)count:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)find:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end