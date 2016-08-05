//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#ifdef OL_KITE_OFFER_FACEBOOK
#ifdef COCOAPODS
#import <NXOAuth2Client/NXOAuth2AccountStore.h>
#else
#import "NXOAuth2AccountStore.h"
#endif
#endif

#ifdef OL_KITE_OFFER_INSTAGRAM
#ifdef COCOAPODS
#import <NXOAuth2Client/NXOAuth2AccountStore.h>
#else
#import "NXOAuth2AccountStore.h"
#endif
#endif

#import "OLKitePrintSDK.h"
#import "OLPayPalCard.h"
#import "OLProductTemplate.h"
#import "OLStripeCard.h"
#ifdef OL_KITE_OFFER_PAYPAL
#ifdef COCOAPODS
#import <PayPal-iOS-SDK/PayPalMobile.h>
#else
#import "PayPalMobile.h"
#endif
#endif

#import "OLProductHomeViewController.h"
#import "OLIntegratedCheckoutViewController.h"
#import "OLKiteABTesting.h"
#import "OLAddressEditViewController.h"
#ifdef OL_KITE_OFFER_APPLE_PAY
#ifdef COCOAPODS
#import <Stripe/Stripe+ApplePay.h>
#else
#import "Stripe+ApplePay.h"
#endif
#endif

#ifdef OL_KITE_OFFER_FACEBOOK
#ifdef COCOAPODS
#import <FBSDKLoginKit/FBSDKLoginManager.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#else
#import "FBSDKLoginManager.h"
#import "FBSDKCoreKit.h"
#endif

#endif
#import "OLPaymentViewController.h"
#import "OLKiteUtils.h"

static NSString *apiKey = nil;
static NSString *const kOLStripePublishableKeyTest = @"pk_test_FxzXniUJWigFysP0bowWbuy3";
static NSString *const kOLStripePublishableKeyLive = @"pk_live_o1egYds0rWu43ln7FjEyOU5E";
static NSString *applePayMerchantID = nil;
static NSString *applePayPayToString = nil;
static OLKitePrintSDKEnvironment environment;

static NSString *const kOLAPIEndpointLive = @"https://api.kite.ly";
static NSString *const kOLAPIEndpointSandbox = @"https://api.kite.ly";
static NSString *const kOLStagingEndpointLive = @"https://staging.kite.ly";
static NSString *const kOLStagingEndpointSandbox = @"https://staging.kite.ly";
static NSString *const kOLPayPalClientIdLive = @"ASYVBBCHF_KwVUstugKy4qvpQaPlUeE_5beKRJHpIP2d3SA_jZrsaUDTmLQY";
static NSString *const kOLPayPalClientIdSandbox = @"AcEcBRDxqcCKiikjm05FyD4Sfi4pkNP98AYN67sr3_yZdBe23xEk0qhdhZLM";
static NSString *const kOLPayPalRecipientEmailLive = @"hello@kite.ly";
static NSString *const kOLPayPalRecipientEmailSandbox = @"sandbox-merchant@kite.ly";
static NSString *const kOLAPIEndpointVersion = @"v3.0";

static BOOL useStripeForCreditCards = YES;
static BOOL cacheTemplates = NO;
static BOOL useStaging = NO;
static BOOL isUnitTesting = NO;
static BOOL QRCodeUploadEnabled = NO;
static BOOL isKiosk = NO;

static NSString *instagramClientID = nil;
static NSString *instagramSecret = nil;
static NSString *instagramRedirectURI = nil;

@interface OLPrintOrder ()
- (void)saveOrder;
@end

@implementation OLKitePrintSDK

+ (BOOL)useStripeForCreditCards {
    return useStripeForCreditCards;
}

+ (void)setUseStripeForCreditCards:(BOOL)use {
    useStripeForCreditCards = use;
}

+ (void)setCacheTemplates:(BOOL)cache{
    if (!cache){
        [OLProductTemplate deleteCachedTemplates];
    }
    cacheTemplates = cache;
}

+ (BOOL)cacheTemplates{
    return cacheTemplates;
}

+ (void)setUseStaging:(BOOL)staging{
    useStaging = staging;
}

+ (void)setIsUnitTesting{
    isUnitTesting = YES;
}

+ (BOOL)isUnitTesting{
    return NO;
}

+ (void)setAPIKey:(NSString *_Nonnull)_apiKey withEnvironment:(OLKitePrintSDKEnvironment)_environment {
    apiKey = _apiKey;
    environment = _environment;
    [OLStripeCard setClientId:[self stripePublishableKey]];
    if (environment == kOLKitePrintSDKEnvironmentLive) {
        [OLPayPalCard setClientId:[self paypalClientId] withEnvironment:kOLPayPalEnvironmentLive];
    } else {
        [OLPayPalCard setClientId:[self paypalClientId] withEnvironment:kOLPayPalEnvironmentSandbox];
    }
}

+ (NSString *_Nullable)apiKey {
    return apiKey;
}

+ (OLKitePrintSDKEnvironment)environment {
    return environment;
}

+ (NSString *)apiEndpoint {
    if (useStaging){
        switch (environment) {
            case kOLKitePrintSDKEnvironmentLive: return kOLStagingEndpointLive;
            case kOLKitePrintSDKEnvironmentSandbox: return kOLStagingEndpointSandbox;
        }
    }
    else{
        switch (environment) {
            case kOLKitePrintSDKEnvironmentLive: return kOLAPIEndpointLive;
            case kOLKitePrintSDKEnvironmentSandbox: return kOLAPIEndpointSandbox;
        }
    }
}

+ (NSString *)apiVersion{
    return kOLAPIEndpointVersion;
}

+ (void) addPushDeviceToken:(NSData *)deviceToken{
    [OLAnalytics addPushDeviceToken:deviceToken];
}

#ifdef OL_KITE_OFFER_PAYPAL
+ (NSString *_Nonnull)paypalEnvironment {
    switch (environment) {
        case kOLKitePrintSDKEnvironmentLive: return PayPalEnvironmentProduction;
        case kOLKitePrintSDKEnvironmentSandbox: return PayPalEnvironmentSandbox;
    }
}
#endif

+ (NSString *_Nonnull)paypalClientId {
    switch (environment) {
        case kOLKitePrintSDKEnvironmentLive: return kOLPayPalClientIdLive;
        case kOLKitePrintSDKEnvironmentSandbox: return kOLPayPalClientIdSandbox;
    }
}

+ (void)setApplePayMerchantID:(NSString *_Nonnull)mID{
#ifdef OL_KITE_OFFER_APPLE_PAY
    applePayMerchantID = mID;
#endif
}

+ (void)setApplePayPayToString:(NSString *_Nonnull)name{
#ifdef OL_KITE_OFFER_APPLE_PAY
    applePayPayToString = name;
#endif
}

+ (NSString *)applePayPayToString{
    if (applePayPayToString){
        return applePayPayToString;
    }
    else{
        NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
        NSString *bundleName = nil;
        if ([info objectForKey:@"CFBundleDisplayName"] == nil) {
            bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *) kCFBundleNameKey];
        } else {
            bundleName = [NSString stringWithFormat:@"%@", [info objectForKey:@"CFBundleDisplayName"]];
        }
        
        return [NSString stringWithFormat:@"Kite.ly (via %@)", bundleName];
    }
}

+ (NSString *_Nonnull)appleMerchantID {
    return applePayMerchantID;
}

+ (NSString *_Nonnull)stripePublishableKey {
    switch (environment) {
        case kOLKitePrintSDKEnvironmentLive: return kOLStripePublishableKeyLive;
        case kOLKitePrintSDKEnvironmentSandbox: return kOLStripePublishableKeyTest;
    }
}

+ (NSString *)qualityGuaranteeString{
    return NSLocalizedString(@"**Quality Guarantee**\nOur products are of the highest quality and we’re confident you will love yours. If not, we offer a no quibble money back guarantee. Enjoy!", @"");
}

+ (void)setIsKiosk:(BOOL)enabled{
    isKiosk = enabled;
}

+ (BOOL)isKiosk{
    return isKiosk;
}

+ (void)setQRCodeUploadEnabled:(BOOL)enabled{
    QRCodeUploadEnabled = enabled;
}

+ (BOOL)QRCodeUploadEnabled{
    return QRCodeUploadEnabled;
}

+ (void)endCustomerSession{
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    [printOrder saveOrder];
    
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [NSArray arrayWithArray:[storage cookies]];
    for (cookie in cookies) {
        if ([cookie.domain containsString:@"instagram.com"]) {
            [storage deleteCookie:cookie];
        }
    }

    NSArray *instagramAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"instagram"];
    for (NXOAuth2Account *account in instagramAccounts) {
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];
    }
    
#ifdef OL_KITE_OFFER_FACEBOOK
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    [loginManager logOut];
    [FBSDKAccessToken setCurrentAccessToken:nil];
#endif
    
    [OLKiteABTesting sharedInstance].theme.kioskShipToStoreAddress.recipientLastName = nil;
    [OLKiteABTesting sharedInstance].theme.kioskShipToStoreAddress.recipientFirstName = nil;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyEmailAddress"];
    [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyPhone"];
    [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyRecipientName"];
    [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyRecipientFirstName"];
    [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyLine1"];
    [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyLine2"];
    [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyCity"];
    [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyCounty"];
    [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyPostCode"];
    [defaults removeObjectForKey:@"co.oceanlabs.pssdk.kKeyCountry"];
    [defaults synchronize];
    
    [OLPayPalCard clearLastUsedCard];
    [OLStripeCard clearLastUsedCard];
}

#pragma mark - Internal


+ (void)setInstagramEnabledWithClientID:(NSString *_Nonnull)clientID secret:(NSString *_Nonnull)secret redirectURI:(NSString *_Nonnull)redirectURI {
    instagramSecret = secret;
    instagramClientID = clientID;
    instagramRedirectURI = redirectURI;
}

+ (NSString *)instagramRedirectURI {
    return instagramRedirectURI;
}

+ (NSString *)instagramSecret{
    return instagramSecret;
}

+ (NSString *)instagramClientID{
    return instagramClientID;
}

@end
