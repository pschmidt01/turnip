//
//  EventDetailsViewController.m
//  turnip
//
//  Created by Per on 4/23/15.
//  Copyright (c) 2015 Per. All rights reserved.
//

#import "EventDetailsViewController.h"
#import "Constants.h"
#import <Parse/Parse.h>

@interface EventDetailsViewController ()

@property (nonatomic, strong) NSMutableArray *pageImages;
@property (nonatomic, strong) NSMutableArray *pageViews;


@property (nonatomic, strong) NSString *objectId;

@end

@implementation EventDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame: CGRectMake(0, 0, 30.0f, 30.0f)];
    
    UIImage *backImage = [self imageResize:[UIImage imageNamed:@"backNav"] andResizeTo:CGSizeMake(30, 30)];
    [backButton setBackgroundImage:backImage  forState:UIControlStateNormal];
    [backButton setTitle:@"" forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backNavigation) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = backButtonItem;
    
    self.title = [self.event valueForKey:@"title"];
    
    self.pageImages = [[NSMutableArray alloc] initWithCapacity:3];
    
    [self downloadDetails];
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Set up the content size of the scroll view
    CGSize pagesScrollViewSize = self.scrollView.frame.size;
    NSLog(@"size: %f", pagesScrollViewSize.width);
    
    self.scrollView.contentSize = CGSizeMake(pagesScrollViewSize.width * self.pageImages.count, pagesScrollViewSize.height);
    
    // Load the initial set of pages that are on screen
    [self loadVisiblePages];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ImageScroller

- (void)loadVisiblePages {
    // First, determine which page is currently visible
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
    
    // Update the page control
    self.pageControl.currentPage = page;
    
    // Work out which pages we want to load
    NSInteger firstPage = page - 1;
    NSInteger lastPage = page + 1;
    
    // Purge anything before the first page
    for (NSInteger i=0; i<firstPage; i++) {
        [self purgePage:i];
    }
    for (NSInteger i=firstPage; i<=lastPage; i++) {
        [self loadPage:i];
    }
    for (NSInteger i=lastPage+1; i<self.pageImages.count; i++) {
        [self purgePage:i];
    }
}

- (void)loadPage:(NSInteger)page {
    if (page < 0 || page >= self.pageImages.count) {
        // If it's outside the range of what we have to display, then do nothing
        return;
    }
    // Load an individual page, first seeing if we've already loaded it
    UIView *pageView = [self.pageViews objectAtIndex:page];
    if ((NSNull*)pageView == [NSNull null]) {
        CGRect frame = self.scrollView.bounds;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0.0f;
        
        UIImageView *newPageView = [[UIImageView alloc] initWithImage:[self.pageImages objectAtIndex:page]];
        newPageView.contentMode = UIViewContentModeScaleAspectFill;
        newPageView.frame = frame;
        [self.scrollView addSubview:newPageView];
        [self.pageViews replaceObjectAtIndex:page withObject:newPageView];
    }
}

- (void)purgePage:(NSInteger)page {
    if (page < 0 || page >= self.pageImages.count) {
        // If it's outside the range of what we have to display, then do nothing
        return;
    }
    
    // Remove a page from the scroll view and reset the container array
    UIView *pageView = [self.pageViews objectAtIndex:page];
    if ((NSNull*)pageView != [NSNull null]) {
        [pageView removeFromSuperview];
        [self.pageViews replaceObjectAtIndex:page withObject:[NSNull null]];
    }
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    [self loadVisiblePages];
}

#pragma mark - parse Download

- (void) downloadDetails {
    self.imageLoader.hidden = NO;
    [self.imageLoader startAnimating];
    
    PFQuery *query = [PFQuery queryWithClassName:TurnipParsePostClassName];
    
    //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query includeKey:TurnipParsePostUserKey];
    [query includeKey:@"neighbourhood"];
    [query whereKey:TurnipParsePostIdKey equalTo:[self.event valueForKey:@"objectId"]];
    
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (error) {
            NSLog(@"Error in query!: %@", error);
        } else {
            if ([[object objectForKey:@"denied"] containsObject:[PFUser currentUser].objectId]) {
                NSLog(@"denied");
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    PFRelation *acceptedRelation = [object relationForKey:@"accepted"];
                    PFQuery *query = [acceptedRelation query];
                    [query whereKey:TurnipParsePostIdKey equalTo:[PFUser currentUser].objectId];
                    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        if ([objects count] == 0) {
                            PFRelation *requestRelation = [object relationForKey:@"requests"];
                            PFQuery *query = [requestRelation query];
                            [query whereKey:TurnipParsePostIdKey equalTo:[PFUser currentUser].objectId];
                            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                                if ([objects count] == 0) {
                                    self.requestButton.enabled = YES;
                                }
                            }];
                        } else {
                            self.requestButton.hidden = YES;
                            // Initialize the refresh control.
//                            self.accepted = [[NSArray alloc] initWithArray:objects];
//                            [[self tableView] reloadData];
//                            self.tableView.hidden = NO;
                        }
                    }];
                });
            }
           // self.data = [[NSArray alloc] initWithObjects:object, nil];
            [self downloadImages: object];
            [self updateUI: object];
        }
    }];
}

- (void) downloadImages: (PFObject *) data {
    // Set up the image we want to scroll & zoom and add it to the scroll view
    if([data objectForKey:@"image1"] != nil) {
        NSURL *url = [NSURL URLWithString: [(PFFile *)[data objectForKey:TurnipParsePostImageOneKey] url]];
        NSData *data = [NSData dataWithContentsOfURL:url];
             [self.pageImages addObject:[UIImage imageWithData:data]];
    }
    
    if([data objectForKey:@"image2"] != nil) {
        NSURL *url = [NSURL URLWithString: [(PFFile *)[data objectForKey:TurnipParsePostImageTwoKey] url]];
        NSData *data = [NSData dataWithContentsOfURL:url];
       [self.pageImages addObject:[UIImage imageWithData:data]];
    }
    
    if([data objectForKey:@"image3"] != nil) {
        NSURL *url = [NSURL URLWithString: [(PFFile *)[data objectForKey:TurnipParsePostImageThreeKey] url]];
        NSData *data = [NSData dataWithContentsOfURL:url];
        [self.pageImages addObject:[UIImage imageWithData:data]];
    }
                      
    if ([[data objectForKey:TurnipParsePostUserKey] valueForKey:@"profileImage"] != nil) {
        NSURL *url = [NSURL URLWithString: [[data objectForKey:TurnipParsePostUserKey] valueForKey:@"profileImage"]];
        NSData *data = [NSData dataWithContentsOfURL:url];
        self.profileImage.image = [UIImage imageWithData:data];
    } else {
        [self downloadFacebookProfilePicture:[data[@"user"] objectForKey:@"facebookId"]];
    }
    
    NSInteger pageCount = self.pageImages.count;
    
    // Set up the page control
    self.pageControl.currentPage = 0;
    self.pageControl.numberOfPages = pageCount;
    
    // Set up the array to hold the views for each page
    self.pageViews = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < pageCount; ++i) {
        [self.pageViews addObject:[NSNull null]];
    }
    self.imageLoader.hidden = YES;
    [self.imageLoader stopAnimating];
}

- (void) updateUI: (PFObject *) data {
    
//#define kBoarderWidth 3.0
//#define kCornerRadius 8.0
//    CALayer *borderLayer = [CALayer layer];
//    CGRect borderFrame = CGRectMake(0, 0, (imageView.frame.size.width), (imageView.frame.size.height));
//    [borderLayer setBackgroundColor:[[UIColor clearColor] CGColor]];
//    [borderLayer setFrame:borderFrame];
//    [borderLayer setCornerRadius:kCornerRadius];
//    [borderLayer setBorderWidth:kBorderWidth];
//    [borderLayer setBorderColor:[[UIColor redColor] CGColor]];
//    [imageView.layer addSublayer:borderLayer];
  
    NSArray *name = [[[data objectForKey:TurnipParsePostUserKey] valueForKey:@"name"] componentsSeparatedByString: @" "];
    NSString *age = @([self calculateAge:[[data objectForKey:TurnipParsePostUserKey] valueForKey:@"birthday"]]).stringValue;
    [[data objectForKey:TurnipParsePostUserKey] valueForKey:@"birthday"];
    
    NSString *nameAge = [NSString stringWithFormat:@"%@ - %@", [name objectAtIndex:0], age];
    
    self.nameLabel.text = nameAge;
    self.aboutLabel.numberOfLines = 0;
    self.aboutLabel.text = [data objectForKey:TurnipParsePostTextKey];
    [self.aboutLabel sizeToFit];
    self.neighbourhoodLabel.text = [[data objectForKey:@"neighbourhood"] valueForKey:@"name"];
    
    self.dateLabel.text = [self convertDate:[data objectForKey:TurnipParsePostDateKey]];
    self.capacityLabel.text = [NSString stringWithFormat:@"Capacity: %@", [data objectForKey:TurnipParsePostCapacityKey] ];
    
    if ([[[data objectForKey:TurnipParsePostUserKey] objectId] isEqual:[PFUser currentUser].objectId]) {
        self.requestButton.hidden = YES;
        self.messageButton.hidden = YES;
      //  self.tableView.hidden = NO;
     //   [self queryForAcceptedUsers];
    }
    
   
    NSString *price = @"";
    NSString *open = @"";
    
    if ([[data objectForKey:TurnipParsePostPrivateKey] isEqual:@"True"]) {
        open  = @"Private";
    } else if([[data objectForKey:TurnipParsePostPrivateKey] isEqual:@"False"]) {
        open = @"Public";
        self.requestButton.hidden = YES;
       // self.attendButton.hidden = NO;
    }
    
    if ([[data objectForKey:TurnipParsePostPaidKey] isEqual:@"True"]) {
        price = @"Free";
    } else if([[data objectForKey:TurnipParsePostPaidKey] isEqual:@"False"]) {
       price = [NSString stringWithFormat:@"$%@",[data objectForKey:TurnipParsePostPriceKey]];
    }
    
    self.privateLabel.text = [NSString stringWithFormat:@"%@, %@", open, price];
}

- (void) downloadFacebookProfilePicture: (NSString *) facebookId {
    
    // URL should point to https://graph.facebook.com/{facebookId}/picture?type=large&return_ssl_resources=1
    NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookId]];
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:pictureURL];
    
    // Run network request asynchronously
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
         if (connectionError == nil && data != nil) {
             // Set the image in the header imageView
             self.profileImage.image = [UIImage imageWithData:data];
         }
     }];
}

#pragma mark -
#pragma mark utils

- (NSString *) convertDate: (NSDate *) date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    NSLocale *locale = [NSLocale currentLocale];
    [dateFormatter setLocale:locale];
    
    [dateFormatter setDoesRelativeDateFormatting:YES];
    
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    return dateString;
}

- (NSInteger) calculateAge: (NSString *) birthday {
    
    NSDate *todayDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    int time = [todayDate timeIntervalSinceDate:[dateFormatter dateFromString:birthday]];
    int allDays = (((time/60)/60)/24);
    int days = allDays%365;
    int years = (allDays-days)/365;
    
    return  years;
}

- (UIImage *)imageResize :(UIImage*)img andResizeTo:(CGSize)newSize
{
    CGFloat scale = [[UIScreen mainScreen]scale];
    /*You can remove the below comment if you dont want to scale the image in retina   device .Dont forget to comment UIGraphicsBeginImageContextWithOptions*/
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, scale);
    [img drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - buttons

-(void) backNavigation {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)messageButton:(id)sender {
}

- (IBAction)requestButton:(id)sender {
    
//    NSString *host = [[[self.data valueForKey:@"user"] valueForKey:@"objectId"] objectAtIndex:0];
//    NSArray *name = [[[PFUser currentUser] objectForKey:@"name"] componentsSeparatedByString: @" "];
//    
//    NSString *message = [NSString stringWithFormat:@"%@ Wants to go to your party", [name objectAtIndex:0]];
//    
//    self.requestButton.enabled = NO;
//    
//    [PFCloud callFunctionInBackground:@"requestEventPush"
//                       withParameters:@{@"recipientId": host, @"message": message, @"eventId": [[self.data valueForKey:TurnipParsePostIdKey] objectAtIndex:0] }
//                                block:^(NSString *success, NSError *error) {
//                                    if (!error) {
//                                        NSLog(@"push sent");
//                                    }
//                                }];

}

- (IBAction)nextImageButton:(id)sender {
    NSLog(@"page: %ld", (long)self.pageControl.currentPage);
    NSInteger page = self.pageControl.currentPage;
    
    [self.pageControl setCurrentPage:1];
    //[self loadPage:self.pageControl.currentPage + 1];
    [self loadVisiblePages];
}
@end