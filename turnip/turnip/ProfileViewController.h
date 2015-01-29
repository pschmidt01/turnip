//
//  ProfileViewController.h
//  turnip
//
//  Created by Per on 1/19/15.
//  Copyright (c) 2015 Per. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface ProfileViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *profileImage;

@property (strong, nonatomic) PFUser *user;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;

@property (strong, nonatomic) IBOutlet UILabel *ageLabel;

@end