/*
 * Copyright 2018 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <TargetConditionals.h>
#if TARGET_OS_IOS

#import "FirebaseInAppMessaging/Sources/DefaultUI/FIRCore+InAppMessagingDisplay.h"
#import "FirebaseInAppMessaging/Sources/DefaultUI/ImageOnly/FIRIAMImageOnlyViewController.h"

@interface FIRIAMImageOnlyViewController ()

@property(nonatomic, readwrite) FIRInAppMessagingImageOnlyDisplay *imageOnlyMessage;

@property(weak, nonatomic) IBOutlet UIImageView *imageView;
@property(weak, nonatomic) IBOutlet UIButton *closeButton;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightConstraint;


@property(nonatomic, assign) CGSize imageOriginalSize;
@end

@implementation FIRIAMImageOnlyViewController

+ (FIRIAMImageOnlyViewController *)
    instantiateViewControllerWithResourceBundle:(NSBundle *)resourceBundle
                                 displayMessage:
                                     (FIRInAppMessagingImageOnlyDisplay *)imageOnlyMessage
                                displayDelegate:
                                    (id<FIRInAppMessagingDisplayDelegate>)displayDelegate
                                    timeFetcher:(id<FIRIAMTimeFetcher>)timeFetcher {
  UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"FIRInAppMessageDisplayStoryboard"
                                                       bundle:resourceBundle];

  if (storyboard == nil) {
    FIRLogError(kFIRLoggerInAppMessagingDisplay, @"I-FID300002",
                @"Storyboard '"
                 "FIRInAppMessageDisplayStoryboard' not found in bundle %@",
                resourceBundle);
    return nil;
  }
  FIRIAMImageOnlyViewController *imageOnlyVC = (FIRIAMImageOnlyViewController *)[storyboard
      instantiateViewControllerWithIdentifier:@"image-only-vc"];
  imageOnlyVC.displayDelegate = displayDelegate;
  imageOnlyVC.imageOnlyMessage = imageOnlyMessage;
  imageOnlyVC.timeFetcher = timeFetcher;

  return imageOnlyVC;
}

- (FIRInAppMessagingDisplayMessage *)inAppMessage {
  return self.imageOnlyMessage;
}

- (IBAction)closeButtonClicked:(id)sender {
  [self dismissView:FIRInAppMessagingDismissTypeUserTapClose];
}

- (void)setupRecognizers {
  UITapGestureRecognizer *tapGestureRecognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(messageTapped:)];
  tapGestureRecognizer.delaysTouchesBegan = YES;
  tapGestureRecognizer.numberOfTapsRequired = 1;

  self.imageView.userInteractionEnabled = YES;
  [self.imageView addGestureRecognizer:tapGestureRecognizer];
}

- (void)messageTapped:(UITapGestureRecognizer *)recognizer {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  FIRInAppMessagingAction *action =
      [[FIRInAppMessagingAction alloc] initWithActionText:nil
                                                actionURL:self.imageOnlyMessage.actionURL];
#pragma clang diagnostic pop
  [self followAction:action];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.view setBackgroundColor:[UIColor.blackColor colorWithAlphaComponent:0.7]];

  // Close button should be announced last for better VoiceOver experience.
  self.view.accessibilityElements = @[ self.imageView, self.closeButton ];

  if (self.imageOnlyMessage.imageData) {
    UIImage *image = [UIImage imageWithData:self.imageOnlyMessage.imageData.imageRawData];
    self.imageOriginalSize = image.size;
    [self.imageView setImage:image];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.accessibilityLabel = self.inAppMessage.campaignInfo.campaignName;
  } else {
    self.imageView.isAccessibilityElement = NO;
  }

  [self setupRecognizers];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

  if (!self.imageOnlyMessage.imageData) {
    return;
  }
    
    if (CGSizeEqualToSize(self.imageOriginalSize, CGSizeZero)) {
        return;
    }
    
    CGFloat ratio = self.imageOriginalSize.height / self.imageOriginalSize.width;
    
    CGFloat width = self.imageView.frame.size.width;
    CGFloat height = width * ratio;
    self.imageViewHeightConstraint.constant = height;
    
  [self.view bringSubviewToFront:self.closeButton];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  // close any potential keyboard, which would conflict with the modal in-app messagine view
  [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder)
                                             to:nil
                                           from:nil
                                       forEvent:nil];
  if (self.imageOnlyMessage.campaignInfo.renderAsTestMessage) {
    FIRLogDebug(kFIRLoggerInAppMessagingDisplay, @"I-FID110004",
                @"Flashing the close button since this is a test message.");
    [self flashCloseButton:self.closeButton];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  // Announce via VoiceOver that the image-only message has appeared. Highlight the image.
  UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.imageView);
}

- (void)flashCloseButton:(UIButton *)closeButton {
  closeButton.alpha = 1.0f;
  [UIView animateWithDuration:2.0
                        delay:0.0
                      options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionRepeat |
                              UIViewAnimationOptionAutoreverse |
                              UIViewAnimationOptionAllowUserInteraction
                   animations:^{
                     closeButton.alpha = 0.1f;
                   }
                   completion:^(BOOL finished){
                       // Do nothing
                   }];
}
@end

#endif  // TARGET_OS_IOS
