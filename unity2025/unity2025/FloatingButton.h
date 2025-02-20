//
//  FloatingButton.h
//  unity2025
//
//  Created by xuzhengda on 2/17/25.
//
#import <UIKit/UIKit.h>
@interface FloatingButton : UIButton
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) BOOL isDragging;
- (void)startSearchingAnimation;
- (void)stopSearchingAnimation;
@end
