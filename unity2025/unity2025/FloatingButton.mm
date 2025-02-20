//
//  FloatingButton.mm
//  unity2025
//
//  Created by xuzhengda on 2/17/25.
//
#import "FloatingButton.h"
#import "p_inc.h"
@implementation FloatingButton{
    CAShapeLayer *_loadingLayer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.isDragging = NO;
        self.userInteractionEnabled = YES;
    }
    return self;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    XLog(@"touchesBegan in")
//    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    self.startPoint = [touch locationInView:self];
    self.isDragging = NO;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [super touchesMoved:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.superview];
    
    // 判断是否开始拖动
    CGPoint touchPoint = [touch locationInView:self];
    if (!self.isDragging && hypot(touchPoint.x - self.startPoint.x, touchPoint.y - self.startPoint.y) > 5.0) {
        self.isDragging = YES;
    }
    
    if (self.isDragging) {
        CGFloat x = point.x - self.startPoint.x;
        CGFloat y = point.y - self.startPoint.y;
        
        CGFloat maxX = self.superview.bounds.size.width - self.frame.size.width;
        CGFloat maxY = self.superview.bounds.size.height - self.frame.size.height;
        
        x = MAX(0, MIN(x, maxX));
        y = MAX(0, MIN(y, maxY));
        
        self.frame = CGRectMake(x, y, self.frame.size.width, self.frame.size.height);
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [super touchesEnded:touches withEvent:event];
    if (!self.isDragging ) {
    
        [self sendActionsForControlEvents:UIControlEventTouchUpInside];

    }
    self.isDragging = NO;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.isDragging = NO;
}

- (void)startSearchingAnimation {
    if (_loadingLayer) return;
    
    // 创建环形进度条
    CGFloat lineWidth = 3.0f;
    CGRect rect = CGRectInset(self.bounds, lineWidth/2, lineWidth/2);
    
    _loadingLayer = [CAShapeLayer layer];
    _loadingLayer.frame = self.bounds;
    _loadingLayer.strokeColor = [UIColor whiteColor].CGColor;
    _loadingLayer.fillColor = [UIColor clearColor].CGColor;
    _loadingLayer.lineWidth = lineWidth;
    _loadingLayer.path = [UIBezierPath bezierPathWithOvalInRect:rect].CGPath;
    _loadingLayer.strokeEnd = 0.4;
    
    // 添加光点效果
    CALayer *dotLayer = [CALayer layer];
    dotLayer.frame = CGRectMake(rect.size.width/2 - 2, 0, 4, 4);
    dotLayer.backgroundColor = [UIColor redColor].CGColor;
    dotLayer.cornerRadius = 2;
    [_loadingLayer addSublayer:dotLayer];
    
    [self.layer addSublayer:_loadingLayer];
    
    // 旋转动画
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotation.toValue = @(M_PI * 2);
    rotation.duration = 1.5;
    rotation.repeatCount = INFINITY;
    [_loadingLayer addAnimation:rotation forKey:@"rotation"];
    
    // 添加渐变色
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = _loadingLayer.bounds;
    gradient.colors = @[(id)[UIColor redColor].CGColor,
                       (id)[UIColor yellowColor].CGColor];
    gradient.startPoint = CGPointMake(0, 0.5);
    gradient.endPoint = CGPointMake(1, 0.5);
    [_loadingLayer addSublayer:gradient];
    _loadingLayer.mask = gradient;
    
    // 添加粒子效果
    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    emitter.emitterPosition = CGPointMake(CGRectGetMidX(self.bounds),
                                        CGRectGetMidY(self.bounds));
    emitter.emitterShape = kCAEmitterLayerCircle;
    emitter.emitterSize = CGSizeMake(10, 10);
    
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.contents = (id)[UIImage imageNamed:@"spark"].CGImage;
    cell.birthRate = 10;
    cell.lifetime = 1.5;
    cell.velocity = 100;
    cell.emissionRange = M_PI * 2;
    [self.layer addSublayer:emitter];
}

- (void)stopSearchingAnimation {
    [_loadingLayer removeAllAnimations];
    [_loadingLayer removeFromSuperlayer];
    _loadingLayer = nil;
}
@end
