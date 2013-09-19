#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import <EventKitUI/EventKitUI.h>
#import <EventKit/EventKit.h>

@interface CameraRoll : CDVPlugin

@property (nonatomic, retain) EKEventStore* eventStore;

- (void)initEventStoreWithCameraRollCapabilities;

-(NSArray*)findEKEventsWithTitle: (NSString *)title
                        location: (NSString *)location
                         message: (NSString *)message
                       startDate: (NSDate *)startDate
                         endDate: (NSDate *)endDate;

// CameraRoll Instance methods

- (void)createEvent:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)modifyEvent:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)findEvent:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)deleteEvent:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end