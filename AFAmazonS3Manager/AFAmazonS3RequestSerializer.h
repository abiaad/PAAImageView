// AFAmazonS3RequestSerializer.h
//
// Copyright (c) 2011–2014 AFNetworking (http://afnetworking.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFURLRequestSerialization.h"

/**
 `AFAmazonS3RequestSerializer` is an `AFHTTPRequestSerializer` subclass with convenience methods for creating requests for the Amazon S3 webservice, including creating an authorization header and building an endpoint URL for a given bucket, region, and TLS preferences.
 */
@interface AFAmazonS3RequestSerializer : AFHTTPRequestSerializer

/**
 The S3 bucket for the client. `nil` by default.

 @see `AFAmazonS3Manager -baseURL`
 */
@property (nonatomic, copy) NSString *bucket;

/**
 The AWS region for the client. `AFAmazonS3USStandardRegion` by default. Must not be `nil`. See "AWS Regions" for defined constant values.

 @see `AFAmazonS3Manager -baseURL`
 */
@property (nonatomic, copy) NSString *region;

/**
 The AWS STS session token. `nil` by default.
 */
@property (nonatomic, copy) NSString *sessionToken;

/**
 Whether to connect over HTTPS. `YES` by default.

 @see `AFAmazonS3Manager -baseURL`
 */
@property (nonatomic, assign) BOOL useSSL;

/**
 A readonly endpoint URL created for the specified bucket, region, and TLS preference. `AFAmazonS3Manager` uses this as a `baseURL` unless one is manually specified.
 */
@property (readonly, nonatomic, copy) NSURL *endpointURL;

/**
 Sets the access key ID and secret, used to generate authorization headers.

 @param accessKey The Amazon S3 Access Key ID.
 @param secret The Amazon S3 Secret.

 @discussion These values can be found on the AWS control panel: http://aws-portal.amazon.com/gp/aws/developer/account/index.html?action=access-key
 */
- (void)setAccessKeyID:(NSString *)accessKey
                secret:(NSString *)secret;

/**
 Returns a request with the necessary AWS authorization HTTP header fields from the specified request using the provided credentials.

 @param request The request.
 @param error The error that occured while constructing the request.

 @return The request with necessary `Authorization` and `Date` HTTP header fields.
 */
- (NSURLRequest *)requestBySettingAuthorizationHeadersForRequest:(NSURLRequest *)request
                                                           error:(NSError * __autoreleasing *)error;

/**
 Returns a request with pre-signed credentials in the query string.

 @param request The request. `HTTPMethod` must be `GET`.
 @param expiration The request expiration. If `nil`, defaults to 1 hour from when method is called.
 @param error The error that occured while constructing the request.

 @return The request with credentials signed in query string.
 */
- (NSURLRequest *)preSignedRequestWithRequest:(NSURLRequest *)request
                                   expiration:(NSDate *)expiration
                                        error:(NSError * __autoreleasing *)error;

@end

///----------------
/// @name Constants
///----------------

/**
 ## AWS Regions

 The following AWS regions are defined:

 `AFAmazonS3USStandardRegion`: US Standard (s3.amazonaws.com);
 `AFAmazonS3USWest1Region`: US West (Oregon) Region (s3-us-west-1.amazonaws.com)
 `AFAmazonS3USWest2Region`: US West (Northern California) Region (s3-us-west-2.amazonaws.com)
 `AFAmazonS3EUWest1Region`: EU (Ireland) Region (s3-eu-west-1.amazonaws.com)
 `AFAmazonS3APSoutheast1Region`: Asia Pacific (Singapore) Region (s3-ap-southeast-1.amazonaws.com)
 `AFAmazonS3APSoutheast2Region`: Asia Pacific (Sydney) Region (s3-ap-southeast-2.amazonaws.com)
 `AFAmazonS3APNortheast2Region`: Asia Pacific (Tokyo) Region (s3-ap-northeast-1.amazonaws.com)
 `AFAmazonS3SAEast1Region`: South America (Sao Paulo) Region (s3-sa-east-1.amazonaws.com)

 For a full list of available regions, see http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
 */
extern NSString * const AFAmazonS3USStandardRegion;
extern NSString * const AFAmazonS3USWest1Region;
extern NSString * const AFAmazonS3USWest2Region;
extern NSString * const AFAmazonS3EUWest1Region;
extern NSString * const AFAmazonS3APSoutheast1Region;
extern NSString * const AFAmazonS3APSoutheast2Region;
extern NSString * const AFAmazonS3APNortheast2Region;
extern NSString * const AFAmazonS3SAEast1Region;
