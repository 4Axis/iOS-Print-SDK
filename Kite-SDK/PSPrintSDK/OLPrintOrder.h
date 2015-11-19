//
//  OLPrintOrder.h
//  Kite SDK
//
//  Created by Deon Botha on 30/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLAddress;
@class OLPaymentLineItem;
@class OLPrintOrderCostRequest;
@class OLPrintOrderCost;

@protocol OLPrintJob;

/**
 *  Progress handler for OLPrintOrder upload
 *
 *  @param totalAssetsUploaded            The number of assets uploaded
 *  @param totalAssetsToUpload            The number of assets to be uploaded
 *  @param totalAssetBytesWritten         The number of asset bytes uploaded
 *  @param totalAssetBytesExpectedToWrite The number of asset bytes expected to be uploaded
 *  @param totalBytesWritten              The number of bytes uploaded
 *  @param totalBytesExpectedToWrite      The number of bytes expected to be uploaded
 */
typedef void (^OLPrintOrderProgressHandler)(NSUInteger totalAssetsUploaded, NSUInteger totalAssetsToUpload, long long totalAssetBytesWritten, long long totalAssetBytesExpectedToWrite, long long totalBytesWritten, long long totalBytesExpectedToWrite);

/**
 *  Completion handler for OLPrintOrder upload
 *
 *  @param orderIdReceipt The order receipt
 *  @param error          The error
 */
typedef void (^OLPrintOrderCompletionHandler)(NSString *orderIdReceipt, NSError *error);

/**
 *  Completion handler for order cost
 *
 *  @param cost  The cost
 *  @param error The error
 */
typedef void (^OLPrintOrderCostCompletionHandler)(OLPrintOrderCost *cost, NSError * error);

/**
 *   States for the order submission status.
 */
typedef NS_ENUM(NSInteger, OLPrintOrderSubmitStatus) {
    /**
     *  The order was canceleld (eg refunded)
     */
    OLPrintOrderSubmitStatusCancelled = -2,
    /**
     *  The order did not validate (eg credit card declined)
     */
    OLPrintOrderSubmitStatusError = -1,
    /**
     *  Status unknown (eg order not submitted)
     */
    OLPrintOrderSubmitStatusUnknown = 0,
    /**
     *  Order received by Kite
     */
    OLPrintOrderSubmitStatusReceived = 1,
    /**
     *  Order accepted by Kite
     */
    OLPrintOrderSubmitStatusAccepted = 2,
    /**
     *  Order validated
     */
    OLPrintOrderSubmitStatusValidated = 3,
    /**
     *  Order processed
     */
    OLPrintOrderSubmitStatusProcessed = 4
};

/**
 *  The print order object, which can have multiple jobs and is ultimately submitted to Kite for printing.
 */
@interface OLPrintOrder : NSObject <NSCoding>

/**
 *  The customer's email address
 */
@property (strong, nonatomic) NSString *email;

/**
 *  The customer's phone number
 */
@property (strong, nonatomic) NSString *phone;

/**
 *  Create, submit for printing, and return a new OLPrintOrder object, based on a single job.
 *
 *  @param job               The job to form the print order
 *  @param proofOfPayment    The proof of payment to validate that user has actually paid for the job
 *  @param progressHandler   Block to track progress
 *  @param completionHandler Block to execute on completion
 *
 *  @return The print order
 */
+ (OLPrintOrder *)submitJob:(id<OLPrintJob>)job withProofOfPayment:(NSString *)proofOfPayment forPrintingWithProgressHandler:(OLPrintOrderProgressHandler)progressHandler completionHandler:(OLPrintOrderCompletionHandler)completionHandler;

/**
 *  Returns the OLPrintOrderSubmissionStatus from an NSString
 *
 *  @param identifier The NSString status
 *
 *  @return The enum version of the status
 */
+ (OLPrintOrderSubmitStatus)submitStatusFromIdentifier:(NSString *)identifier;

/**
 *  Add a print job to the print order
 *
 *  @param job The job to add
 */
- (void)addPrintJob:(id<OLPrintJob>)job;

/**
 *  Removed a print job from the print order
 *
 *  @param job The job to remove
 */
- (void)removePrintJob:(id<OLPrintJob>)job;

/**
 *  Submit the print order for printing
 *
 *  @param completionHandler Block to execute on completion
 */
- (void)submitForPrintingWithCompletionHandler:(OLPrintOrderCompletionHandler)completionHandler;

/**
 *  Submit the print order for printing
 *
 *  @param progressHandler   Block to track progress
 *  @param completionHandler Block to execute on completion
 */
- (void)submitForPrintingWithProgressHandler:(OLPrintOrderProgressHandler)progressHandler completionHandler:(OLPrintOrderCompletionHandler)completionHandler;

/**
 *  Cancels both preempted asset upload and submission for printing
 */
- (void)cancelSubmissionOrPreemptedAssetUpload;

/**
 *  Preempting asset upload kicks off the asset upload process early before the print order has even been submited to the system for processing. This incurs no cost to you and allows for a speedier checkout process as it gives the option to begin the asset uploading whilst the user is still filling out details.
 */
- (void)preemptAssetUpload;

/**
 *  The shipping address of the print order
 * @warning If individual print jobs have their address property set, those will take precedence over this.
 */
@property (nonatomic, strong) OLAddress *shippingAddress;

/**
 *  The proof that the user has paid. Usually comes in some form of "receipt" or token from payment processors like PayPal and Stripe.
 */
@property (nonatomic, strong) NSString *proofOfPayment;

/**
 *  A promo code that a user might have obtained and entered
 */
@property (nonatomic, strong) NSString *promoCode;

/**
 *  The jobs to print
 */
@property (nonatomic, readonly) NSArray *jobs;

/**
 *  The number of assets across all jobs that need uploading
 */
@property (nonatomic, readonly) NSUInteger totalAssetsToUpload;

/**
 *  YES if submission for printing was successful and receipt will be non nil.
 */
@property (nonatomic, readonly) BOOL printed;

/**
 *  The date of the last submission
 */
@property (nonatomic, readonly) NSDate *lastPrintSubmissionDate;

/**
 *  The error of the last submission
 */
@property (nonatomic, readonly) NSError *lastPrintSubmissionError;

/**
 *  The receipt of the submission. Will be a Kite order ID if successful but can be a proof of payment if the user has paid but the submission has failed.
 */
@property (nonatomic, readonly) NSString *receipt;

/**
 *  Extra information
 */
@property (nonatomic, strong) NSDictionary *userData;

/**
 *  The currencies supported by this print order
 */
@property (nonatomic, readonly) NSArray *currenciesSupported;

/**
 *  The currency code this print order is set to
 */
@property (nonatomic, copy) NSString *currencyCode;

/**
 *  A description of the payment
 */
@property (nonatomic, readonly) NSString *paymentDescription;

/**
 *  State of the print order submission.
 */
@property (assign, nonatomic, readonly) OLPrintOrderSubmitStatus submitStatus;

/**
 *  The error message when the order submit status has changed to Error
 */
@property (strong, nonatomic) NSString *submitStatusErrorMessage;

/**
 *  If duplicate jobs are found, discard
 */
- (void)discardDuplicateJobs;

/**
 *  Duplicate jobs for different user addresses. This is useful for when a user wants to send the same order to multiple addresses.
 *  @warning This will multiply the number of jobs by the number of addresses provided. If you want to send specific jobs to multiple addresses, do that manually.
 *
 *  @param addresses The addresses to send copies of the whole order to.
 */
- (void)duplicateJobsForAddresses:(NSArray *)addresses;

/**
 *  Request the cost of the print order from Kite
 *
 *  @param handler Block to call when we have the cost ready.
 */
- (void)costWithCompletionHandler:(OLPrintOrderCostCompletionHandler)handler;

/**
 *  Return the shipping addresses of all jobs
 *
 *  @return The shipping addresses.
 */
- (NSArray <OLAddress *>*)shippingAddressesOfJobs;

@end
