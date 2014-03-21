# PAImageView
============

**Rounded async imageview downloader based on AFNetworking 2 and lightly cached

## Snapshot

![Snapshop PASwitch](https://raw.github.com/abiaad/paimageview/master/snapshot.gif)

## Usage

```objective-c
PAImageView *avatarView = [[PAImageView alloc] initWithFrame:aFrame backgroundProgressColor:[UIColor whiteColor] progressColor:[UIColor lightGrayColor]];
[self.view addSubview:_image];
// Later
[_image setImageURL:URL];
```
