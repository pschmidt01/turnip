//
//  SAEFeedEvent.m
//  turnip
//
//  Created by Per on 8/7/15.
//  Copyright (c) 2015 Stupidest App Ever. All rights reserved.
//

#import "SAEFeedEvent.h"

@interface SAEFeedEvent ()

@property (nonatomic, copy) NSString *objectId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSDate *date;

@end

@implementation SAEFeedEvent

- (instancetype) initWithImage:(UIImage *)eventImage
                         title:(NSString *)title
                      objectId:(NSString *)objectId
                          date:(NSDate *)date
                          host:(PFUser *)host
                     attendees:(NSArray *)attendees
                          text:(NSString *)text
                       address:(NSString *)address
                        isFree:(BOOL *)isFree
                     isPrivate:(BOOL *)isPrivate
                 neighbourhood:(PFObject *)neighbourhood {
    self = [super init];
    if (self) {
      
    }
    return self;
}

- (instancetype) initWithImage:(UIImage *)eventImage
                      objectId:(NSString *)objectId
                         title:(NSString *)title
                          date:(NSDate *)date
                          host:(PFUser *)host
                     attendees:(NSArray *)attendees {
    self = [super init];
    
    if (self) {
        self.eventImage = eventImage;
        self.objectId = objectId;
        self.title = title;
        self.date = date;
        self.host = host;
        self.attendees = attendees;
    }
    return self;
}

@end