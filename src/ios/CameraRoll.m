#import "Calendar.h"
#import <Cordova/CDV.h>
#import <EventKitUI/EventKitUI.h>
#import <EventKit/EventKit.h>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation CameraRoll
@synthesize eventStore;

#pragma mark Initialisation functions

- (CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (CameraRoll*)[super initWithWebView:theWebView];
    if (self) {
		//[self setup];
        [self initEventStoreWithCameraRollCapabilities];
    }
    return self;
}

- (void)initEventStoreWithCameraRollCapabilities {
    __block BOOL accessGranted = NO;
    eventStore= [[EKEventStore alloc] init];
    if([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    } else { // we're on iOS 5 or older
        accessGranted = YES;
    }
    
    if (accessGranted) {
        self.eventStore = eventStore;
    }
}

#pragma mark Helper Functions

-(NSArray*)findEKEventsWithTitle: (NSString *)title
                        location: (NSString *)location
                         message: (NSString *)message
                       startDate: (NSDate *)startDate
                         endDate: (NSDate *)endDate {

    // Build up a predicateString - this means we only query a parameter if we actually had a value in it
    NSMutableString *predicateString= [[NSMutableString alloc] initWithString:@""];
    if (title.length > 0) {
        [predicateString appendString:[NSString stringWithFormat:@"title == '%@'" , title]];
    }
    if (location.length > 0) {
        [predicateString appendString:[NSString stringWithFormat:@" AND location == '%@'" , location]];
    }
    if (message.length > 0) {
        [predicateString appendString:[NSString stringWithFormat:@" AND notes == '%@'" , message]];
    }
    
    NSPredicate *matches = [NSPredicate predicateWithFormat:predicateString];
    
    NSArray *datedEvents = [self.eventStore eventsMatchingPredicate:[eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:nil]];
    
    
    NSArray *matchingEvents = [datedEvents filteredArrayUsingPredicate:matches];
    
    
    return matchingEvents;
}

#pragma mark Cordova functions

- (void)createEvent:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
    // Import arguments
    
    NSString *callbackId = [arguments pop];
    
    NSString* title      = [arguments objectAtIndex:0];
    NSString* location   = [arguments objectAtIndex:1];
    NSString* message    = [arguments objectAtIndex:2];
    NSString *startDate  = [arguments objectAtIndex:3];
    NSString *endDate    = [arguments objectAtIndex:4];
    
    NSTimeInterval _startInterval = [startDate doubleValue] / 1000; // strip millis
    NSDate *myStartDate = [NSDate dateWithTimeIntervalSince1970:_startInterval];
    
    NSTimeInterval _endInterval = [endDate doubleValue] / 1000; // strip millis
    
    EKEvent *myEvent = [EKEvent eventWithEventStore: self.eventStore];
    myEvent.title = title;
    myEvent.location = location;
    myEvent.notes = message;
    myEvent.startDate = myStartDate;
    
    int duration = _endInterval - _startInterval;
    int moduloDay = duration % (60*60*24);
    if (moduloDay == 0) {
        myEvent.allDay = YES;
        myEvent.endDate = [NSDate dateWithTimeIntervalSince1970:_endInterval-1];
    } else {
        myEvent.endDate = [NSDate dateWithTimeIntervalSince1970:_endInterval];
    }
    myEvent.cameraRoll = self.eventStore.defaultCameraRollForNewEvents;
    
    EKAlarm *reminder = [EKAlarm alarmWithRelativeOffset:-2*60*60];
    
    [myEvent addAlarm:reminder];
    
    NSError *error = nil;
    [self.eventStore saveEvent:myEvent span:EKSpanThisEvent error:&error];

    if (error) {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.userInfo.description];
        [self writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
    } else {
        NSLog(@"Reached Success");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
    }
}

-(void)deleteEvent:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
    // Import arguments
    
    NSString *callbackId = [arguments pop];
    
    NSString* title      = [arguments objectAtIndex:0];
    NSString* location   = [arguments objectAtIndex:1];
    NSString* message    = [arguments objectAtIndex:2];
    NSString *startDate  = [arguments objectAtIndex:3];
    NSString *endDate    = [arguments objectAtIndex:4];
    
    NSTimeInterval _startInterval = [startDate doubleValue] / 1000; // strip millis
    NSDate *myStartDate = [NSDate dateWithTimeIntervalSince1970:_startInterval];
    
    NSTimeInterval _endInterval = [endDate doubleValue] / 1000; // strip millis
    NSDate *myEndDate = [NSDate dateWithTimeIntervalSince1970:_endInterval];
    
    NSArray *matchingEvents = [self findEKEventsWithTitle:title location:location message:message startDate:myStartDate endDate:myEndDate];
    
    NSError *error = NULL;
    for (EKEvent * event in matchingEvents) {
        [self.eventStore removeEvent:event span:EKSpanThisEvent error:&error];
    }
    // Check for error codes and return result
    if (error) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.userInfo.description];
        [self writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
    } else {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
    }
}

-(void)findEvent:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
    // Import arguments
    
    NSString *callbackId = [arguments pop];
    
    NSString* title      = [arguments objectAtIndex:0];
    NSString* location   = [arguments objectAtIndex:1];
    NSString* message    = [arguments objectAtIndex:2];
    NSString *startDate  = [arguments objectAtIndex:3];
    NSString *endDate    = [arguments objectAtIndex:4];
    
    NSTimeInterval _startInterval = [startDate doubleValue] / 1000; // strip millis
    NSDate *myStartDate = [NSDate dateWithTimeIntervalSince1970:_startInterval];
    
    NSTimeInterval _endInterval = [endDate doubleValue] / 1000; // strip millis
    NSDate *myEndDate = [NSDate dateWithTimeIntervalSince1970:_endInterval];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSArray *matchingEvents = [self findEKEventsWithTitle:title location:location message:message startDate:myStartDate endDate:myEndDate];
    
    NSMutableArray *finalResults = [[NSMutableArray alloc] initWithCapacity:matchingEvents.count];
    
    
    // Stringify the results - Cordova can't deal with Obj-C objects
    for (EKEvent * event in matchingEvents) {
        NSMutableDictionary *entry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                      event.title, @"title",
                                      event.location, @"location",
                                      event.notes, @"message",
                                      [df stringFromDate:event.startDate], @"startDate",
                                      [df stringFromDate:event.endDate], @"endDate", nil];
        [finalResults addObject:entry];
    }
    
    if (finalResults.count > 0) {
        // Return the results we got
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus: CDVCommandStatus_OK
                                   messageAsArray:finalResults
                                   ];
        [self writeJavascript:[result toSuccessCallbackString:callbackId]];
    }
    else {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
        [self writeJavascript:[result toErrorCallbackString:callbackId]];
    }
    
}


-(void)modifyEvent:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
    // Import arguments
    
    NSString *callbackId = [arguments pop];
    
    NSString* title      = [arguments objectAtIndex:0];
    NSString* location   = [arguments objectAtIndex:1];
    NSString* message    = [arguments objectAtIndex:2];
    NSString *startDate  = [arguments objectAtIndex:3];
    NSString *endDate    = [arguments objectAtIndex:4];
    
    NSString* ntitle      = [arguments objectAtIndex:5];
    NSString* nlocation   = [arguments objectAtIndex:6];
    NSString* nmessage    = [arguments objectAtIndex:7];
    NSString *nstartDate  = [arguments objectAtIndex:8];
    NSString *nendDate    = [arguments objectAtIndex:9];
    
    NSTimeInterval _startInterval = [startDate doubleValue] / 1000; // strip millis
    NSDate *myStartDate = [NSDate dateWithTimeIntervalSince1970:_startInterval];
    
    NSTimeInterval _endInterval = [endDate doubleValue] / 1000; // strip millis
    NSDate *myEndDate = [NSDate dateWithTimeIntervalSince1970:_endInterval];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    // Find matches
    NSArray *matchingEvents = [self findEKEventsWithTitle:title location:location message:message startDate:myStartDate endDate:myEndDate];
    
    if (matchingEvents.count == 1) {
        // Presume we have to have an exact match to modify it!
        // Need to load this event from an EKEventStore so we can edit it
        EKEvent *theEvent = [self.eventStore eventWithIdentifier:((EKEvent*)[matchingEvents lastObject]).eventIdentifier];
        if (ntitle) {
            theEvent.title = ntitle;
        }
        if (nlocation) {
            theEvent.location = nlocation;
        }
        if (nmessage) {
            theEvent.notes = nmessage;
        }
        if (nstartDate) {
            NSTimeInterval _nstartInterval = [nstartDate doubleValue] / 1000; // strip millis
            theEvent.startDate = [NSDate dateWithTimeIntervalSince1970:_nstartInterval];
        }
        if (nendDate) {
            NSTimeInterval _nendInterval = [nendDate doubleValue] / 1000; // strip millis
            theEvent.endDate = [NSDate dateWithTimeIntervalSince1970:_nendInterval];
        }
        
        // Now save the new details back to the store
        NSError *error = nil;
        [self.eventStore saveEvent:theEvent span:EKSpanThisEvent error:&error];
        
        // Check error code + return result
        if (error) {
            CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.userInfo.description];
            [self writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
        } else {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
        }
    } else {
        // Otherwise return a no result error
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
        [self writeJavascript:[pluginResult toErrorCallbackString:callbackId]];
    }
}

@end