//
//  MapMarker.h
//  turnip
//
//  Created by Per on 1/15/15.
//  Copyright (c) 2015 Per. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>

@interface MapMarker: GMSMarker

@property (nonatomic, copy) NSString *objectId;
@property (nonatomic, assign) BOOL drawn;

@end
