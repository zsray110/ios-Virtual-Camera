#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

// --- 接口声明：告诉编译器这些方法是存在的 ---
@interface UIViewController (VirtualCamera)
- (void)handleMenuTap:(UITapGestureRecognizer *)sender;
@end

// --- 全局静态变量 ---
static UILabel *debugLabel = nil;
static BOOL isVideoReplaceEnabled = YES;
static NSString *selectedVideoPath = nil;
static BOOL hasShownInitialAlert = NO;

// --- 工具函数：显示菜单 ---
static void showVideoMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"虚拟相机" message:@"请选择视频源" preferredStyle:UIAlertControllerStyleAlert];
        
        for (int i = 1; i <= 3; i++) {
            NSString *name = [NSString stringWithFormat:@"视频%d", i];
            [alert addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                selectedVideoPath = [docs stringByAppendingFormat:@"/Videos/%@.mp4", name];
                isVideoReplaceEnabled = YES;
                NSLog(@"[VC] 已选择视频: %@", selectedVideoPath);
            }]];
        }
        
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow ?: [[UIApplication sharedApplication].windows firstObject];
        UIViewController *root = window.rootViewController;
        while (root.presentedViewController) root = root.presentedViewController;
        [root presentViewController:alert animated:YES completion:nil];
    });
}

// --- Hook 摄像头核心 ---
%hook AVCaptureDevice
+ (id)deviceWithUniqueID:(id)arg1 {
    if (isVideoReplaceEnabled && selectedVideoPath) {
        NSLog(@"[VC] 正在拦截摄像头: %@", arg1);
    }
    return %orig;
}
%end

// --- Hook UI 触发菜单 ---
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (!hasShownInitialAlert) {
        hasShownInitialAlert = YES;
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow ?: [[UIApplication sharedApplication].windows firstObject];
        // 创建一个透明的顶部点击区
        UIView *tapArea = [[UIView alloc] initWithFrame:CGRectMake(0, 0, window.bounds.size.width, 60)];
        tapArea.backgroundColor = [[UIColor clearColor] colorWithAlphaComponent:0.01];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuTap:)];
        [tapArea addGestureRecognizer:tap];
        [window addSubview:tapArea];
        [window bringSubviewToFront:tapArea];
    }
}

%new
- (void)handleMenuTap:(UITapGestureRecognizer *)sender {
    showVideoMenu();
}
%end

%ctor {
    NSLog(@"[VC] 插件已加载");
}
