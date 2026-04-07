#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

// --- 声明部分：防止 Exit Code 2 编译报错 ---
@interface UIViewController (VCMenu)
- (void)handleTapToOpenMenu:(UITapGestureRecognizer *)sender;
@end

static BOOL isVCEnabled = YES;
static NSString *videoPath = nil;
static BOOL initialAlertDone = NO;

// --- 菜单逻辑 ---
static void showVCMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"虚拟相机" message:@"选择功能" preferredStyle:UIAlertControllerStyleAlert];
        
        [menu addAction:[UIAlertAction actionWithTitle:@"选择视频1" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            videoPath = [docs stringByAppendingString:@"/Videos/1.mp4"];
            isVCEnabled = YES;
        }]];
        
        [menu addAction:[UIAlertAction actionWithTitle:@"关闭替换" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            isVCEnabled = NO;
        }]];
        
        [menu addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        
        UIWindow *win = [UIApplication sharedApplication].keyWindow ?: [[UIApplication sharedApplication].windows firstObject];
        UIViewController *top = win.rootViewController;
        while (top.presentedViewController) top = top.presentedViewController;
        [top presentViewController:menu animated:YES completion:nil];
    });
}

// --- Hook 摄像头 ---
%hook AVCaptureDevice
+ (id)deviceWithUniqueID:(id)arg1 {
    if (isVCEnabled && videoPath) {
        NSLog(@"[VirtualCamera] 成功拦截设备请求");
    }
    return %orig;
}
%end

// --- Hook 界面触发器 ---
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (!initialAlertDone) {
        initialAlertDone = YES;
        
        UIWindow *win = [UIApplication sharedApplication].keyWindow ?: [[UIApplication sharedApplication].windows firstObject];
        // 在屏幕顶部创建一个隐形的点击区域
        UIView *trigger = [[UIView alloc] initWithFrame:CGRectMake(0, 0, win.bounds.size.width, 50)];
        trigger.backgroundColor = [[UIColor clearColor] colorWithAlphaComponent:0.01];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapToOpenMenu:)];
        [trigger addGestureRecognizer:tap];
        [win addSubview:trigger];
        [win bringSubviewToFront:trigger];
    }
}

%new
- (void)handleTapToOpenMenu:(UITapGestureRecognizer *)sender {
    showVCMenu();
}
%end
