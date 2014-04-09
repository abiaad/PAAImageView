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

- (void)setImage:(UIImage *)image forURL:(NSString *)URL;
- (UIImage *)getImageForURL:(NSString *)URL;

@end

#pragma mark - SPMImageAsyncView interface

@interface PAImageView ()

@property (nonatomic, strong) CAShapeLayer *backgroundLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;

@property (nonatomic, strong) UIImageView *containerImageView;
@property (nonatomic, strong) UIView      *progressContainer;

@property (nonatomic, strong) SPMImageCache *cache;

@end

#pragma mark - SPMImageAsyncView


@implementation PAImageView

- (id)initWithFrame:(CGRect)frame {
    return [[PAImageView alloc] initWithFrame:frame
                            backgroundProgressColor:[UIColor whiteColor]
                                      progressColor:[UIColor colorWithRed:240/255.f green:85/255.f blue:97/255.f alpha:1.f]];
}

- (id)initWithFrame:(CGRect)frame backgroundProgressColor:(UIColor *)backgroundProgresscolor progressColor:(UIColor *)progressColor
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.layer.cornerRadius     = CGRectGetWidth(self.bounds)/2.f;
        self.layer.masksToBounds    = NO;
        self.clipsToBounds          = YES;
        _cache = [[SPMImageCache alloc] init];
        
        CGPoint arcCenter           = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        CGFloat radius              = MIN(CGRectGetMidX(self.bounds)-1, CGRectGetMidY(self.bounds)-1);
        
        UIBezierPath *circlePath    = [UIBezierPath bezierPathWithArcCenter:arcCenter
                                                                     radius:radius
                                                                 startAngle:-rad(90)
                                                                   endAngle:rad(360-90)
                                                                  clockwise:YES];
        
        _backgroundLayer = [CAShapeLayer layer];
        _backgroundLayer.path           = circlePath.CGPath;
        _backgroundLayer.strokeColor    = [backgroundProgresscolor CGColor];
        _backgroundLayer.fillColor      = [[UIColor clearColor] CGColor];
        _backgroundLayer.lineWidth      = kLineWidth;
        
        
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.path         = _backgroundLayer.path;
        _progressLayer.strokeColor  = [progressColor CGColor];
        _progressLayer.fillColor    = _backgroundLayer.fillColor;
        _progressLayer.lineWidth    = _backgroundLayer.lineWidth;
        _progressLayer.strokeEnd    = 0.f;
        
        
        _progressContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _progressContainer.layer.cornerRadius   = CGRectGetWidth(self.bounds)/2.f;
        _progressContainer.layer.masksToBounds  = NO;
        _progressContainer.clipsToBounds        = YES;
        _progressContainer.backgroundColor      = [UIColor clearColor];
        
        _containerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(1, 1, frame.size.width-2, frame.size.height-2)];
        _containerImageView.layer.cornerRadius = CGRectGetWidth(self.bounds)/2.f;
        _containerImageView.layer.masksToBounds = NO;
        _containerImageView.clipsToBounds = YES;
        _containerImageView.contentMode = UIViewContentModeScaleAspectFill;
        
        [_progressContainer.layer addSublayer:_backgroundLayer];
        [_progressContainer.layer addSublayer:_progressLayer];
        
        [self addSubview:_containerImageView];
        [self addSubview:_progressContainer];
    }
    return self;
}

- (void)setImageURL:(NSString *)URL {
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    UIImage *cachedImage = (_cacheEnabled) ? [_cache getImageForURL:URL] : nil;
    if(cachedImage) {
        [self updateWithImage:cachedImage animated:NO];
    } else {
        __weak __typeof(self)weakSelf = self;
        AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
        requestOperation.responseSerializer = [AFImageResponseSerializer serializer];
        [requestOperation setDownloadProgressBlock:^(NSUInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
            CGFloat progress = (CGFloat)totalBytesRead/(CGFloat)totalBytesExpectedToRead;
            
            _progressLayer.strokeEnd        = progress;
            _backgroundLayer.strokeStart    = progress;
        }];
        [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            UIImage *image = responseObject;
            [weakSelf updateWithImage:image animated:YES];
            if(_cacheEnabled) {
                [_cache setImage:responseObject forURL:URL];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Image error: %@", error);
        }];
        [requestOperation start];
    }
}

- (void)updateWithImage:(UIImage *)image animated:(BOOL)animated {
    
    CGFloat duration    = (animated) ? 0.3 : 0.f;
    CGFloat delay       = (animated) ? 0.1 : 0.f;
    
    _containerImageView.transform   = CGAffineTransformMakeScale(0, 0);
    _containerImageView.alpha       = 0.f;
    _containerImageView.image       = image;
    
    [UIView animateWithDuration:duration
                     animations:^{
                         _progressContainer.transform    = CGAffineTransformMakeScale(1.1, 1.1);
                         _progressContainer.alpha        = 0.f;
                         [UIView animateWithDuration:duration
                                               delay:delay
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              _containerImageView.transform   = CGAffineTransformIdentity;
                                              _containerImageView.alpha       = 1.f;
                                          } completion:nil];
                     } completion:^(BOOL finished) {
                         _progressLayer.strokeColor = [[UIColor whiteColor] CGColor];
                         [UIView animateWithDuration:duration
                                          animations:^{
                                              _progressContainer.transform    = CGAffineTransformIdentity;
                                              _progressContainer.alpha        = 1.f;
                                          }];
                     }];
}


@end

#pragma mark - SPMImageCache

@implementation SPMImageCache

- (instancetype)init {
    self = [super init];
    if(self) {
        NSArray  *paths         = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *rootCachePath = [paths firstObject];

        _fileManager    = [NSFileManager defaultManager];
        _cachePath      = [rootCachePath stringByAppendingPathComponent:spm_identifier];
        
        if(![_fileManager fileExistsAtPath:spm_identifier]) {
            [_fileManager createDirectoryAtPath:_cachePath withIntermediateDirectories:NO attributes:nil error:nil];
        }
    }
    return self;
}

- (void)setImage:(UIImage *)image forURL:(NSString *)URL {
    
    NSData   *imageData = nil;
    NSString *fileExtension = [[URL componentsSeparatedByString:@"."] lastObject];
    if([fileExtension isEqualToString:@"png"]) {
        imageData       = UIImagePNGRepresentation(image);
    } else if([fileExtension isEqualToString:@"jpg"] || [fileExtension isEqualToString:@"jpeg"]) {
        imageData       = UIImageJPEGRepresentation(image, 1.f);
    } else return;
    
    [imageData writeToFile:[_cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%u.%@", URL.hash, fileExtension]] atomically:YES];
}

- (UIImage *)getImageForURL:(NSString *)URL {
    NSString *fileExtension = [[URL componentsSeparatedByString:@"."] lastObject];
    NSString *path = [_cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%u.%@", URL.hash, fileExtension]];
    if([_fileManager fileExistsAtPath:path]) {
        return [UIImage imageWithData:[NSData dataWithContentsOfFile:path]];
    }
    return nil;
}

@end
