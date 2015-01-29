//
//  DetailViewController.h
//  turnip
//
//  Created by Per on 1/14/15.
//  Copyright (c) 2015 Per. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "TurnipEvent.h"

@interface DetailViewController : UIViewController

@property (nonatomic, strong) TurnipEvent *event;
@property (nonatomic, strong) NSString *objectId;

- (IBAction)profileImageTapHandler:(UITapGestureRecognizer *)sender;

@property (strong, nonatomic) IBOutlet UILabel *aboutLabel;

@property (strong, nonatomic) IBOutlet PFImageView *imageView1;

@property (strong, nonatomic) IBOutlet PFImageView *imageView2;

@property (strong, nonatomic) IBOutlet PFImageView *imageView3;
@property (strong, nonatomic) IBOutlet PFImageView *profileImage;

@end
