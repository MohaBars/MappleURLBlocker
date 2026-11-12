#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - URL filtering

static BOOL MUBIsHTTPURL(NSURL *url) {
    if (![url isKindOfClass:[NSURL class]]) {
        return NO;
    }

    NSString *scheme = url.scheme.lowercaseString;
    return [scheme isEqualToString:@"http"] ||
           [scheme isEqualToString:@"https"];
}

static BOOL MUBShouldBlockURL(NSURL *url) {
    // This dylib should be assigned only to Mapple in LiveContainer.
    // Block external web handoffs, but leave mailto:, tel:, and custom
    // URL schemes alone.
    return MUBIsHTTPURL(url);
}

#pragma mark - UIApplication hooks

@interface UIApplication (MappleURLBlocker)
- (BOOL)mub_original_openURL:(NSURL *)url;
- (void)mub_original_openURL:(NSURL *)url
                     options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options
           completionHandler:(void (^)(BOOL success))completion;
@end

@implementation UIApplication (MappleURLBlocker)

- (BOOL)mub_original_openURL:(NSURL *)url {
    if (MUBShouldBlockURL(url)) {
        NSLog(@"[MappleURLBlocker] Blocked external URL: %@", url.absoluteString);
        return NO;
    }

    return [self mub_original_openURL:url];
}

- (void)mub_original_openURL:(NSURL *)url
                     options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options
           completionHandler:(void (^)(BOOL success))completion {
    if (MUBShouldBlockURL(url)) {
        NSLog(@"[MappleURLBlocker] Blocked external URL: %@", url.absoluteString);
        if (completion) {
            completion(NO);
        }
        return;
    }

    [self mub_original_openURL:url options:options completionHandler:completion];
}

@end

#pragma mark - Installation

static void MUBSwizzleInstanceMethod(Class cls, SEL originalSelector, SEL replacementSelector) {
    Method original = class_getInstanceMethod(cls, originalSelector);
    Method replacement = class_getInstanceMethod(cls, replacementSelector);

    if (!original || !replacement) {
        NSLog(@"[MappleURLBlocker] Could not find method to swizzle: %@",
              NSStringFromSelector(originalSelector));
        return;
    }

    // class_addMethod handles methods inherited from a superclass safely... I think
    BOOL added = class_addMethod(cls,
                                 originalSelector,
                                 method_getImplementation(replacement),
                                 method_getTypeEncoding(replacement));

    if (added) {
        class_replaceMethod(cls,
                            replacementSelector,
                            method_getImplementation(original),
                            method_getTypeEncoding(original));
    } else {
        method_exchangeImplementations(original, replacement);
    }

    NSLog(@"[MappleURLBlocker] Hook installed: %@",
          NSStringFromSelector(originalSelector));
}

__attribute__((constructor))
static void MUBInitialize(void) {
    @autoreleasepool {
        Class applicationClass = objc_getClass("UIApplication");
        if (!applicationClass) {
            NSLog(@"[MappleURLBlocker] UIApplication not found; not an app process?");
            return;
        }

        MUBSwizzleInstanceMethod(applicationClass,
                                 @selector(openURL:),
                                 @selector(mub_original_openURL:));

        MUBSwizzleInstanceMethod(applicationClass,
                                 @selector(openURL:options:completionHandler:),
                                 @selector(mub_original_openURL:options:completionHandler:));

        NSLog(@"[MappleURLBlocker] Loaded. HTTP/HTTPS external URL launches will be blocked.");
    }
}
