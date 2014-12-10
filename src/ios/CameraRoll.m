#import "CameraRoll.h"
#import <Cordova/CDV.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation CameraRoll


-(void)count:(CDVInvokedUrlCommand*)command {
    
    BOOL includePhotos = [command.arguments objectAtIndex:0];
    BOOL includeVideos = [command.arguments objectAtIndex:1];

    ALAssetsFilter *filter;
    if (includePhotos && includeVideos) {
        filter = [ALAssetsFilter allAssets];
    } else if (includePhotos) {
        filter = [ALAssetsFilter allPhotos];
    } else if (includeVideos) {
        filter = [ALAssetsFilter allVideos];
    } else {
        // nothing, so return error
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no result"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }

    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    int __block numAssets = 0;
    [library enumerateGroupsWithTypes:ALAssetsGroupAll
                           usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                               if (group) {
                                   [group setAssetsFilter:filter];
                                   numAssets += group.numberOfAssets;
                               }
                                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:numAssets];
                              [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                           }
     
                         failureBlock:^(NSError *err) {
                          NSLog(@"%@", [err localizedDescription]);
                           CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:err.localizedDescription];
                           [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                         }];
}


-(void)find:(CDVInvokedUrlCommand*)command {

    NSInteger max = [[command.arguments objectAtIndex:0] integerValue];
  
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:ALAssetsGroupAll
                        usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                            if (group == nil) {
                                return;
                            }
                            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *innerStop) {
                                if (result == nil) {
                                    return;
                                }
                                NSURL *urld = (NSURL*) [[result defaultRepresentation]url];
                                NSData *imageData = [NSData dataWithContentsOfURL:urld];
                                NSString *base64EncodedImage = [imageData base64EncodedString];

                                [photos addObject:base64EncodedImage];
                                if (photos.count == max) {
                                    *innerStop = YES;
                                }
                            }];

                            if (photos.count > 0) {
                              CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:photos];
                              [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                            } else {
                              CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                              [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                            }
                        } failureBlock:^(NSError *error) {
                            NSLog(@"%@", [error localizedDescription]);
                            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                        }];
}

@end