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
@property (nonatomic, weak) UIView *alignmentView;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIViewController *zoomedViewController;
@property (nonatomic, weak) UIView *alignmentCoordinateView;
@property (nonatomic, assign) CGRect cachedAlignmentRect;
@property (nonatomic, assign) BOOL hasCachedAlignmentRect;
@property (nonatomic, assign) BOOL interactiveDismissEnabled;
@property (nonatomic, assign) BOOL onlyWhenScrollAtTop;
@property (nonatomic, assign) CGFloat scrollTopTolerance;

- (void)invalidateAlignmentRect;
- (BOOL)refreshAlignmentRectForZoomedView:(UIView *)zoomedView;
- (CGRect)alignmentRectForZoomedView:(UIView *)zoomedView;

@end

@implementation TiZoomTransitionConfiguration

- (void)invalidateAlignmentRect
{
  self.cachedAlignmentRect = CGRectNull;
  self.hasCachedAlignmentRect = NO;
  self.alignmentCoordinateView = nil;
}

- (BOOL)refreshAlignmentRectForZoomedView:(UIView *)zoomedView
{
  UIView *alignmentView = self.alignmentView;
  if (alignmentView == nil || zoomedView == nil) {
    return NO;
  }

  [zoomedView layoutIfNeeded];
  [alignmentView layoutIfNeeded];

  if (alignmentView != zoomedView && ![alignmentView isDescendantOfView:zoomedView]) {
    return NO;
  }

  CGRect alignmentRect = [alignmentView convertRect:alignmentView.bounds toView:zoomedView];
  if (CGRectIsNull(alignmentRect) || CGRectIsInfinite(alignmentRect) || CGRectIsEmpty(alignmentRect)) {
    return NO;
  }

  self.cachedAlignmentRect = alignmentRect;
  self.hasCachedAlignmentRect = YES;
  self.alignmentCoordinateView = zoomedView;
  return YES;
}

- (CGRect)alignmentRectForZoomedView:(UIView *)zoomedView
{
  if (zoomedView == nil) {
    return CGRectNull;
  }

  if (self.hasCachedAlignmentRect && self.alignmentCoordinateView == zoomedView) {
    return self.cachedAlignmentRect;
  }

  if ([self refreshAlignmentRectForZoomedView:zoomedView]) {
    return self.cachedAlignmentRect;
  }

  return CGRectNull;
}

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

    UIView *alignmentView = nil;
    id alignmentObject = [options objectForKey:@"alignmentView"];
    if (alignmentObject != nil && alignmentObject != [NSNull null]) {
      alignmentView = [self viewFromObject:alignmentObject];
      if (alignmentView == nil) {
        [self throwException:@"invalid_alignment_view"
                   subreason:@"Unable to resolve options.alignmentView to a native UIView"
                    location:CODELOCATION];
        return;
      }
    }

    TiZoomTransitionConfiguration *configuration = [TiZoomTransitionConfiguration new];
    configuration.sourceView = sourceView;
    configuration.alignmentView = alignmentView;
    [configuration invalidateAlignmentRect];
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

- (void)setAlignmentView:(id)args
{
  ENSURE_UI_THREAD(setAlignmentView, args);
  ENSURE_ARG_COUNT(args, 2);

  UIViewController *controller = [self controllerFromObject:[args objectAtIndex:0]];
  UIView *alignmentView = [self viewFromObject:[args objectAtIndex:1]];
  TiZoomTransitionConfiguration *configuration = controller == nil
      ? nil
      : objc_getAssociatedObject(controller, kTiZoomTransitionConfigurationKey);

  if (configuration == nil) {
    [self throwException:@"window_not_prepared"
               subreason:@"Call prepareWindow before setAlignmentView"
                location:CODELOCATION];
    return;
  }

  if (alignmentView == nil) {
    [self throwException:@"invalid_alignment_view"
               subreason:@"Unable to resolve the supplied alignment view to a native UIView"
                location:CODELOCATION];
    return;
  }

  BOOL needsUpdatedTransition = configuration.alignmentView == nil;
  configuration.alignmentView = alignmentView;
  [configuration invalidateAlignmentRect];
  [configuration refreshAlignmentRectForZoomedView:controller.view];

  if (needsUpdatedTransition) {
    [self applyConfiguration:configuration toController:controller];
  }
}

- (void)refreshAlignmentRect:(id)args
{
  ENSURE_UI_THREAD(refreshAlignmentRect, args);
  ENSURE_SINGLE_ARG(args, NSObject);

  UIViewController *controller = [self controllerFromObject:args];
  TiZoomTransitionConfiguration *configuration = controller == nil
      ? nil
      : objc_getAssociatedObject(controller, kTiZoomTransitionConfigurationKey);

  if (configuration == nil) {
    [self throwException:@"window_not_prepared"
               subreason:@"Call prepareWindow before refreshAlignmentRect"
                location:CODELOCATION];
    return;
  }

  if (configuration.alignmentView == nil) {
    [self throwException:@"alignment_view_not_configured"
               subreason:@"prepareWindow or setAlignmentView must supply an alignment view"
                location:CODELOCATION];
    return;
  }

  [configuration invalidateAlignmentRect];
  [configuration refreshAlignmentRectForZoomedView:controller.view];
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

    if (configuration.alignmentView != nil) {
      zoomOptions.alignmentRectProvider = ^CGRect(UIZoomTransitionAlignmentRectContext *context) {
        TiZoomTransitionConfiguration *strongConfiguration = weakConfiguration;
        if (strongConfiguration == nil) {
          return CGRectNull;
        }
        return [strongConfiguration alignmentRectForZoomedView:context.zoomedViewController.view];
      };
    }

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
        CGPoint scrollVelocity = [scrollView.panGestureRecognizer velocityInView:scrollView];
        CGPoint scrollTranslation = [scrollView.panGestureRecognizer translationInView:scrollView];
        BOOL contextShowsDownwardIntent =
            velocity.dy > 0.0 && fabs(velocity.dy) >= fabs(velocity.dx) * 0.5;
        BOOL scrollVelocityShowsDownwardIntent =
            scrollVelocity.y > 0.0 && fabs(scrollVelocity.y) >= fabs(scrollVelocity.x) * 0.5;
        BOOL scrollTranslationShowsDownwardIntent =
            scrollTranslation.y > 0.0 && fabs(scrollTranslation.y) >= fabs(scrollTranslation.x) * 0.5;
        BOOL isDownwardVerticalDrag = contextShowsDownwardIntent
            || scrollVelocityShowsDownwardIntent
            || scrollTranslationShowsDownwardIntent;
        if (!isDownwardVerticalDrag) {
          return context.willBegin;
        }

        CGPoint pointInScrollView = [scrollView convertPoint:context.location
                                                     fromView:zoomedViewController.view];
        if (![scrollView pointInside:pointInScrollView withEvent:nil]) {
          return context.willBegin;
        }

        CGFloat topOffset = -scrollView.adjustedContentInset.top;
        BOOL isAtTop = scrollView.contentOffset.y
            <= topOffset + strongConfiguration.scrollTopTolerance;
        if (!isAtTop) {
          return NO;
        }

        return YES;
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
