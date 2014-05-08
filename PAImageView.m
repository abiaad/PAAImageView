//
//  SPMImageAsyncView.m
//  ImageDL
//
//  Created by Pierre Abi-aad on 21/03/2014.
//  Copyright (c) 2014 Pierre Abi-aad. All rights reserved.
//

#import "PAImageView.h"
#import "AFNetworking/AFNetworking.h"

#pragma mark - Utils

#define rad(degrees) ((degrees) / (180.0 / M_PI))
#define kLineWidth 3.f

NSString * const spm_identifier = @"spm.imagecache.tg";

#pragma mark - SPMImageCache interface

@interface SPMImageCache : NSObject

@property (nonatomic, strong) NSString      *cachePath;
@property (nonatomic, strong) NSFileManager *fileManager;

- (void)setImage:(UIImage *)image forURL:(NSURL *)URL;
- (UIImage *)getImageForURL:(NSURL *)URL;

@end

#pragma mark - SPMImageAsyncView interface

@interface PAImageView ()

@property (nonatomic, strong) CAShapeLayer *backgroundLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong, readwrite) UIImageView *containerImageView;
@property (nonatomic, strong) UIView      *progressContainer;

@property (nonatomic, strong) SPMImageCache *cache;

@end

#pragma mark - SPMImageAsyncView


@implementation PAImageView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self commonInitWithFrame:self.frame
          backgroundProgressColor:[UIColor whiteColor]
                    progressColor:[UIColor blueColor]];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    return [[PAImageView alloc] initWithFrame:frame
                      backgroundProgressColor:[UIColor whiteColor]
                                progressColor:[UIColor blueColor]];
}

- (id)initWithFrame:(CGRect)frame backgroundProgressColor:(UIColor *)backgroundProgresscolor progressColor:(UIColor *)progressColor
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInitWithFrame:frame
          backgroundProgressColor:backgroundProgresscolor
                    progressColor:progressColor];
    }
    return self;
}

- (void)commonInitWithFrame:(CGRect)frame backgroundProgressColor:(UIColor *)backgroundProgresscolor progressColor:(UIColor *)progressColor
{
    _backgroundProgresscolor = backgroundProgresscolor;
    _progressColor = progressColor;
    
    self.layer.cornerRadius     = CGRectGetWidth(self.bounds)/2.f;
    self.layer.masksToBounds    = NO;
    self.clipsToBounds          = YES;
    self.cacheEnabled               = YES;
    
    self.cache = [[SPMImageCache alloc] init];
    
    CGPoint arcCenter           = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat radius              = MIN(CGRectGetMidX(self.bounds) - 1, CGRectGetMidY(self.bounds)-1);
    
    UIBezierPath *circlePath    = [UIBezierPath bezierPathWithArcCenter:arcCenter
                                                                 radius:radius
                                                             startAngle:-rad(90)
                                                               endAngle:rad(360-90)
                                                              clockwise:YES];
    
    self.backgroundLayer = [CAShapeLayer layer];
    self.backgroundLayer.path           = circlePath.CGPath;
    self.backgroundLayer.strokeColor    = [backgroundProgresscolor CGColor];
    self.backgroundLayer.fillColor      = [[UIColor clearColor] CGColor];
    self.backgroundLayer.lineWidth      = kLineWidth;
    
    
    self.progressLayer = [CAShapeLayer layer];
    self.progressLayer.path         = self.backgroundLayer.path;
    self.progressLayer.strokeColor  = [progressColor CGColor];
    self.progressLayer.fillColor    = self.backgroundLayer.fillColor;
    self.progressLayer.lineWidth    = self.backgroundLayer.lineWidth;
    self.progressLayer.strokeEnd    = 0.f;
    
    
    self.progressContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    self.progressContainer.layer.cornerRadius   = CGRectGetWidth(self.bounds)/2.f;
    self.progressContainer.layer.masksToBounds  = NO;
    self.progressContainer.clipsToBounds        = YES;
    self.progressContainer.backgroundColor      = [UIColor clearColor];
    
    self.containerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(1, 1, frame.size.width-2, frame.size.height-2)];
    self.containerImageView.layer.cornerRadius = CGRectGetWidth(self.bounds)/2.f;
    self.containerImageView.layer.masksToBounds = NO;
    self.containerImageView.clipsToBounds = YES;
    self.containerImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    [self.progressContainer.layer addSublayer:self.backgroundLayer];
    [self.progressContainer.layer addSublayer:self.progressLayer];
    
    [self addSubview:self.containerImageView];
    [self addSubview:self.progressContainer];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleSingleTap:)];
    [self addGestureRecognizer:tapRecognizer];
}

- (void)handleSingleTap:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(paImageViewDidTapped:)])
    {
        [self.delegate paImageViewDidTapped:self];
    }
}

- (void)setBackgroundProgresscolor:(UIColor *)backgroundProgresscolor
{
    _backgroundProgresscolor = backgroundProgresscolor;
    self.backgroundLayer.strokeColor = [backgroundProgresscolor CGColor];
}

- (void)setProgressColor:(UIColor *)progressColor
{
    _progressColor = progressColor;
    self.progressLayer.strokeColor  = [progressColor CGColor];
}

- (void)setPlaceHolderImage:(UIImage *)placeHolderImage
{
    _placeHolderImage = placeHolderImage;
    if (!self.containerImageView.image)
    {
        self.containerImageView.image = placeHolderImage;
    }
}

- (void)setImageURL:(NSURL *)URL
{
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:URL];
    UIImage *cachedImage = (self.cacheEnabled) ? [self.cache getImageForURL:URL] : nil;
    if(cachedImage)
    {
        [self updateWithImage:cachedImage animated:NO];
    }
    else
    {
        __weak __typeof(self)weakSelf = self;
        AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
        requestOperation.responseSerializer = [AFImageResponseSerializer serializer];
        [requestOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
            CGFloat progress = (CGFloat)totalBytesRead/(CGFloat)totalBytesExpectedToRead;
            
            self.progressLayer.strokeEnd        = progress;
            self.backgroundLayer.strokeStart    = progress;
        }];
        [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            UIImage *image = responseObject;
            [weakSelf updateWithImage:image animated:YES];
            if(self.cacheEnabled)
            {
                [self.cache setImage:responseObject forURL:URL];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Image error: %@", error);
        }];
        [requestOperation start];
    }
}

- (void)updateWithImage:(UIImage *)image animated:(BOOL)animated
{
    CGFloat duration    = (animated) ? 0.3 : 0.f;
    CGFloat delay       = (animated) ? 0.1 : 0.f;
    
    self.containerImageView.transform   = CGAffineTransformMakeScale(0, 0);
    self.containerImageView.alpha       = 0.f;
    self.containerImageView.image       = image;
    
    [UIView animateWithDuration:duration
                     animations:^{
                         self.progressContainer.transform    = CGAffineTransformMakeScale(1.1, 1.1);
                         self.progressContainer.alpha        = 0.f;
                         [UIView animateWithDuration:duration
                                               delay:delay
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              self.containerImageView.transform   = CGAffineTransformIdentity;
                                              self.containerImageView.alpha       = 1.f;
                                          } completion:nil];
                     } completion:^(BOOL finished) {
                         self.progressLayer.strokeColor = [self.progressColor CGColor];
                         [UIView animateWithDuration:duration
                                          animations:^{
                                              self.progressContainer.transform    = CGAffineTransformIdentity;
                                              self.progressContainer.alpha        = 1.f;
                                          }];
                     }];
}


@end

#pragma mark - SPMImageCache

@implementation SPMImageCache

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        NSArray  *paths         = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *rootCachePath = [paths firstObject];

        self.fileManager    = [NSFileManager defaultManager];
        self.cachePath      = [rootCachePath stringByAppendingPathComponent:spm_identifier];
        
        if(![self.fileManager fileExistsAtPath:spm_identifier])
        {
            [self.fileManager createDirectoryAtPath:self.cachePath withIntermediateDirectories:NO attributes:nil error:nil];
        }
    }
    return self;
}

- (void)setImage:(UIImage *)image forURL:(NSURL *)URL
{
    
    NSData   *imageData = nil;
    
    NSString *fileExtension = [URL pathExtension];//[[URL componentsSeparatedByString:@"."] lastObject];
    if([fileExtension isEqualToString:@"png"])
    {
        imageData       = UIImagePNGRepresentation(image);
    }
    else if([fileExtension isEqualToString:@"jpg"] || [fileExtension isEqualToString:@"jpeg"])
    {
        imageData       = UIImageJPEGRepresentation(image, 1.f);
    }
    else
        return;
    
    [imageData writeToFile:[self.cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%u.%@", URL.hash, fileExtension]] atomically:YES];
}

- (UIImage *)getImageForURL:(NSURL *)URL
{
    NSString *fileExtension = [URL pathExtension];//[[URL componentsSeparatedByString:@"."] lastObject];
    NSString *path = [self.cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%u.%@", URL.hash, fileExtension]];
    if([self.fileManager fileExistsAtPath:path])
    {
        return [UIImage imageWithData:[NSData dataWithContentsOfFile:path]];
    }
    return nil;
}

@end
