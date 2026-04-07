#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

// --- 全局变量 ---
static UILabel *debugLabel = nil;
static BOOL isVideoReplaceEnabled = YES;
static NSString *selectedVideoPath = nil;
static BOOL hasShownInitialAlert = NO;

// --- 工具函数：显示日志 ---
static void showDebugLog(NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!debugLabel) {
            UIWindow *window = [UIApplication sharedApplication].keyWindow ?: [[UIApplication sharedApplication].windows firstObject];
            debugLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, window.bounds.size.width - 40, 100)];
            debugLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
            debugLabel.textColor = [UIColor whiteColor];
            debugLabel.numberOfLines = 0;
            debugLabel.font = [UIFont systemFontOfSize:10];
            debugLabel.layer.cornerRadius = 5;
            debugLabel.clipsToBounds = YES;
            debugLabel.userInteractionEnabled = NO;
            [window addSubview:debugLabel];
        }
        debugLabel.text = [NSString stringWithFormat:@"%@\n%@", message, debugLabel.text ?: @""];
    });
}

// --- 工具函数：视频选择菜单 ---
static void showVideoMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"虚拟相机" message:@"请选择视频源" preferredStyle:UIAlertControllerStyleAlert];
        
        for (int i = 1; i <= 3; i++) {
            NSString *name = [NSString stringWithFormat:@"视频%d", i];
            [alert addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                selectedVideoPath = [docs stringByAppendingFormat:@"/Videos/%@.mp4", name];
                isVideoReplaceEnabled = YES;
                showDebugLog([NSString stringWithFormat:@"已选: %@", name]);
            }]];
        }
        
        [alert addAction:[UIAlertAction actionWithTitle:@"关闭插件" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            isVideoReplaceEnabled = NO;
            showDebugLog(@"插件已禁用");
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow ?: [[UIApplication sharedApplication].windows firstObject];
        UIViewController *root = window.rootViewController;
        while (root.presentedViewController) root = root.presentedViewController;
        [root presentViewController:alert animated:YES completion:nil];
    });
}

// --- Hook 核心 ---

%hook AVCaptureDevice
+ (id)deviceWithUniqueID:(id)arg1 {
    if (isVideoReplaceEnabled && selectedVideoPath) {
        NSLog(@"[VirtualCamera] 正在拦截设备: %@", arg1);
    }
    return %orig;
}
%end

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (!hasShownInitialAlert) {
        hasShownInitialAlert = YES;
        showDebugLog(@"虚拟相机注入成功！点击顶部菜单");
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow ?: [[UIApplication sharedApplication].windows firstObject];
        UIView *tapArea = [[UIView alloc] initWithFrame:CGRectMake(0, 0, window.bounds.size.width, 50)];
        tapArea.backgroundColor = [[UIColor clearColor] colorWithAlphaComponent:0.01];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuTap:)];
        [tapArea addGestureRecognizer:tap];
        [window addSubview:tapArea];
    }
}

%new
- (void)handleMenuTap:(UITapGestureRecognizer *)sender {
    showVideoMenu();
}
%end

%ctor {
    NSLog(@"[VirtualCamera] 插件加载成功");
}
