#import "TiZoomtransitionModule.h"
#import "TiUtils.h"
#import "TiViewProxy.h"
#import "TiWindowProxy.h"
#import <UIKit/UIKit.h>
#import <math.h>
#import <objc/runtime.h>

static const void *kTiZoomTransitionConfigurationKey = &kTiZoomTransitionConfigurationKey;

@interface TiZoomTransitionConfiguration : NSObject

@property (nonatomic, weak) UIView *sourceView;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIViewController *zoomedViewController;
@property (nonatomic, assign) BOOL interactiveDismissEnabled;
@property (nonatomic, assign) BOOL onlyWhenScrollAtTop;
@property (nonatomic, assign) CGFloat scrollTopTolerance;

@end

@implementation TiZoomTransitionConfiguration
@end

@interface TiZoomtransitionModule ()

- (UIViewController *)controllerFromObject:(id)object;
- (UIView *)viewFromObject:(id)object;
- (UIScrollView *)scrollViewFromView:(UIView *)view;
- (void)applyConfiguration:(TiZoomTransitionConfiguration *)configuration
              toController:(UIViewController *)controller;

@end

@implementation TiZoomtransitionModule

#pragma mark - Titanium module plumbing

- (NSString *)moduleGUID
{
  return @"7d3d3eb6-eb49-4754-b795-5dd6049f1006";
}

- (NSString *)moduleId
{
  return @"ti.zoomtransition";
}

#pragma mark - Public API

- (NSNumber *)isSupported:(id)unused
{
  if (@available(iOS 18.0, *)) {
    return NUMBOOL(YES);
  }
  return NUMBOOL(NO);
}

- (void)prepareWindow:(id)args
{
  ENSURE_UI_THREAD(prepareWindow, args);
  ENSURE_ARG_COUNT(args, 2);

  id windowObject = [args objectAtIndex:0];
  NSDictionary *options = [args objectAtIndex:1];
  ENSURE_TYPE(options, NSDictionary);

  if (@available(iOS 18.0, *)) {
    id sourceObject = [options objectForKey:@"sourceView"];
    if (sourceObject == nil || sourceObject == [NSNull null]) {
      [self throwException:@"invalid_source_view"
                 subreason:@"prepareWindow requires options.sourceView"
                  location:CODELOCATION];
      return;
    }

    UIViewController *controller = [self controllerFromObject:windowObject];
    UIView *sourceView = [self viewFromObject:sourceObject];

    if (controller == nil) {
      [self throwException:@"invalid_window"
                 subreason:@"Unable to resolve the destination Window's native UIViewController"
                  location:CODELOCATION];
      return;
    }

    if (sourceView == nil) {
      [self throwException:@"invalid_source_view"
                 subreason:@"Unable to resolve options.sourceView to a native UIView"
                  location:CODELOCATION];
      return;
    }

    UIScrollView *scrollView = nil;
    id scrollObject = [options objectForKey:@"scrollView"];
    if (scrollObject != nil && scrollObject != [NSNull null]) {
      scrollView = [self scrollViewFromView:[self viewFromObject:scrollObject]];
      if (scrollView == nil) {
        [self throwException:@"invalid_scroll_view"
                   subreason:@"options.scrollView must resolve to a Ti.UI.ScrollView, TableView, or ListView"
                    location:CODELOCATION];
        return;
      }
    }

    TiZoomTransitionConfiguration *configuration = [TiZoomTransitionConfiguration new];
    configuration.sourceView = sourceView;
    configuration.scrollView = scrollView;
    configuration.zoomedViewController = controller;
    configuration.interactiveDismissEnabled = [TiUtils boolValue:@"interactiveDismiss"
                                                       properties:options
                                                              def:YES];
    configuration.onlyWhenScrollAtTop = [TiUtils boolValue:@"onlyWhenScrollAtTop"
                                                    properties:options
                                                           def:YES];
    configuration.scrollTopTolerance = MAX(0.0,
        [TiUtils floatValue:@"scrollTopTolerance" properties:options def:1.0]);

    if ([TiUtils boolValue:@"fullScreen" properties:options def:NO]) {
      controller.modalPresentationStyle = UIModalPresentationFullScreen;
    }

    objc_setAssociatedObject(controller,
        kTiZoomTransitionConfigurationKey,
        configuration,
        OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [self applyConfiguration:configuration toController:controller];
  }
}

- (void)clearWindow:(id)args
{
  ENSURE_UI_THREAD(clearWindow, args);
  ENSURE_SINGLE_ARG(args, NSObject);

  UIViewController *controller = [self controllerFromObject:args];
  if (controller == nil) {
    return;
  }

  objc_setAssociatedObject(controller,
      kTiZoomTransitionConfigurationKey,
      nil,
      OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  if (@available(iOS 18.0, *)) {
    controller.preferredTransition = nil;
  }
}

- (void)setSourceView:(id)args
{
  ENSURE_UI_THREAD(setSourceView, args);
  ENSURE_ARG_COUNT(args, 2);

  UIViewController *controller = [self controllerFromObject:[args objectAtIndex:0]];
  UIView *sourceView = [self viewFromObject:[args objectAtIndex:1]];
  TiZoomTransitionConfiguration *configuration = controller == nil
      ? nil
      : objc_getAssociatedObject(controller, kTiZoomTransitionConfigurationKey);

  if (configuration == nil) {
    [self throwException:@"window_not_prepared"
               subreason:@"Call prepareWindow before setSourceView"
                location:CODELOCATION];
    return;
  }

  if (sourceView == nil) {
    [self throwException:@"invalid_source_view"
               subreason:@"Unable to resolve the supplied source view to a native UIView"
                location:CODELOCATION];
    return;
  }

  configuration.sourceView = sourceView;
}

#pragma mark - Native object resolution

- (UIViewController *)controllerFromObject:(id)object
{
  if (object == nil || object == [NSNull null]) {
    return nil;
  }

  if ([object isKindOfClass:[UIViewController class]]) {
    return (UIViewController *)object;
  }

  if ([object isKindOfClass:[TiWindowProxy class]]) {
    return [(TiWindowProxy *)object hostingController];
  }

  if ([object respondsToSelector:@selector(hostingController)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id controller = [object performSelector:@selector(hostingController)];
#pragma clang diagnostic pop
    if ([controller isKindOfClass:[UIViewController class]]) {
      return controller;
    }
  }

  if ([object respondsToSelector:@selector(viewController)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id controller = [object performSelector:@selector(viewController)];
#pragma clang diagnostic pop
    if ([controller isKindOfClass:[UIViewController class]]) {
      return controller;
    }
  }

  return nil;
}

- (UIView *)viewFromObject:(id)object
{
  if (object == nil || object == [NSNull null]) {
    return nil;
  }

  if ([object isKindOfClass:[UIView class]]) {
    return (UIView *)object;
  }

  if ([object isKindOfClass:[TiViewProxy class]]) {
    return [(TiViewProxy *)object view];
  }

  if ([object respondsToSelector:@selector(view)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id view = [object performSelector:@selector(view)];
#pragma clang diagnostic pop
    if ([view isKindOfClass:[UIView class]]) {
      return view;
    }
  }

  return nil;
}

- (UIScrollView *)scrollViewFromView:(UIView *)view
{
  if (view == nil) {
    return nil;
  }

  if ([view isKindOfClass:[UIScrollView class]]) {
    return (UIScrollView *)view;
  }

  for (UIView *subview in view.subviews) {
    UIScrollView *scrollView = [self scrollViewFromView:subview];
    if (scrollView != nil) {
      return scrollView;
    }
  }

  return nil;
}

#pragma mark - Zoom transition

- (void)applyConfiguration:(TiZoomTransitionConfiguration *)configuration
              toController:(UIViewController *)controller
{
  if (@available(iOS 18.0, *)) {
    UIZoomTransitionOptions *zoomOptions = [UIZoomTransitionOptions new];
    __weak TiZoomTransitionConfiguration *weakConfiguration = configuration;

    if (!configuration.interactiveDismissEnabled) {
      zoomOptions.interactiveDismissShouldBegin = ^BOOL(UIZoomTransitionInteractionContext *context) {
        return NO;
      };
    } else if (configuration.scrollView != nil && configuration.onlyWhenScrollAtTop) {
      zoomOptions.interactiveDismissShouldBegin = ^BOOL(UIZoomTransitionInteractionContext *context) {
        TiZoomTransitionConfiguration *strongConfiguration = weakConfiguration;
        UIScrollView *scrollView = strongConfiguration.scrollView;
        UIViewController *zoomedViewController = strongConfiguration.zoomedViewController;

        if (strongConfiguration == nil || scrollView == nil || zoomedViewController == nil) {
          return context.willBegin;
        }

        CGVector velocity = context.velocity;
        BOOL isDownwardVerticalDrag = velocity.dy > 0.0 && fabs(velocity.dy) >= fabs(velocity.dx);
        if (!isDownwardVerticalDrag) {
          return context.willBegin;
        }

        CGPoint pointInScrollView = [scrollView convertPoint:context.location
                                                     fromView:zoomedViewController.view];
        if (![scrollView pointInside:pointInScrollView withEvent:nil]) {
          return context.willBegin;
        }

        CGFloat topOffset = -scrollView.adjustedContentInset.top;
        return scrollView.contentOffset.y <= topOffset + strongConfiguration.scrollTopTolerance;
      };
    }

    controller.preferredTransition =
        [UIViewControllerTransition zoomWithOptions:zoomOptions
                                sourceViewProvider:^UIView *(UIZoomTransitionSourceViewProviderContext *context) {
      return weakConfiguration.sourceView;
    }];
  }
}

@end
