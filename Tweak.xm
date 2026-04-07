#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

// --- 必须有的接口声明，防止编译器报错 ---
@interface UIViewController (VirtualCamera)
- (void)handleMenuTap:(UITapGestureRecognizer *)sender;
@end

static UILabel *debugLabel = nil;
static BOOL isVideoReplaceEnabled = YES;
static NSString *selectedVideoPath = nil;
static BOOL hasShownInitialAlert = NO;

// --- 工具函数：显示日志 ---
static void showDebugLog(NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!debugLabel) {
            UIWindow *window = [UIApplication sharedApplication].keyWindow ?: [[UIApplication sharedApplication].windows firstObject];
            debugLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, window.bounds.size.width - 40, 80)];
            debugLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
            debugLabel.textColor = [UIColor whiteColor];
            debugLabel.numberOfLines = 0;
            debugLabel.font = [UIFont systemFontOfSize:10];
            debugLabel.layer.cornerRadius = 5;
            debugLabel.clipsToBounds = YES;
            [window addSubview:debugLabel];
        }
        debugLabel.text = [NSString stringWithFormat:@"%@\n%@", message, debugLabel.text ?: @""];
    });
}

// --- 工具函数：显示菜单 ---
static void showVideoMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"虚拟相机" message:@"请选择视频" preferredStyle:UIAlertControllerStyleAlert];
        
        for (int i = 1; i <= 3; i++) {
            NSString *vName = [NSString stringWithFormat:@"视频%d", i];
            [alert addAction:[UIAlertAction actionWithTitle:vName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                selectedVideoPath = [docs stringByAppendingFormat:@"/Videos/%@.mp4", vName];
                isVideoReplaceEnabled = YES;
                showDebugLog([NSString stringWithFormat:@"已选: %@", vName]);
            }]];
        }
        
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        
        UIWindow *win = [UIApplication sharedApplication].keyWindow ?: [[UIApplication sharedApplication].windows firstObject];
        UIViewController *root = win.rootViewController;
        while (root.presentedViewController) root = root.presentedViewController;
        [root presentViewController:alert animated:YES completion:nil];
    });
}

// --- Hook 核心 ---

%hook AVCaptureDevice
+ (id)deviceWithUniqueID:(id)arg1 {
    if (isVideoReplaceEnabled && selectedVideoPath) {
        NSLog(@"[VC] 拦截设备: %@", arg1);
    }
    return %orig;
}
%end

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (!hasShownInitialAlert) {
        hasShownInitialAlert = YES;
        showDebugLog(@"虚拟相机加载成功，点击顶部触发");
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow ?: [[UIApplication sharedApplication].windows firstObject];
        UIView *tapArea = [[UIView alloc] initWithFrame:CGRectMake(0, 0, window.bounds.size.width, 60)];
        tapArea.backgroundColor = [[UIColor clearColor] colorWithAlphaComponent:0.01];
        
        // 注意：iOS 14 可能需要更明确的手势绑定
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
