//
//  PAAImageView.h
//  ImageDL
//
//  Created by Pierre Abi-aad on 21/03/2014.
//  Copyright (c) 2014 Pierre Abi-aad. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PAAImageViewDelegate <NSObject>
@optional
- (void)paaImageViewDidTapped:(id)view;
@end

@interface PAAImageView : UIView

@property (nonatomic, weak) id<PAAImageViewDelegate> delegate;

@property (nonatomic, assign, getter = isCacheEnabled) BOOL cacheEnabled;
@property (nonatomic, strong) UIImage *placeHolderImage;
@property (nonatomic, strong, readonly) UIImageView *containerImageView;

@property (nonatomic, strong) UIColor *backgroundProgresscolor;
@property (nonatomic, strong) UIColor *progressColor;

- (id)initWithFrame:(CGRect)frame backgroundProgressColor:(UIColor *)backgroundProgresscolor progressColor:(UIColor *)progressColor;
- (void)setImageURL:(NSURL *)URL;
- (void)setImage:(UIImage *)image;

- (void)setBackgroundWidth:(CGFloat)width;

@end
