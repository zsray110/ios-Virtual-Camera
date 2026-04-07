#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

// --- 前向声明 ---
@interface UIViewController (VolumeExtension)
- (void)handlePan:(UIPanGestureRecognizer *)pan;
- (void)tapViewTapped:(UITapGestureRecognizer *)gestureRecognizer;
@end

static UILabel *debugLabel = nil;
static UIViewController *currentViewController = nil;
static BOOL isVideoReplaceEnabled = YES;
static NSString *selectedVideoPath = nil;
static BOOL hasShownInitialAlert = NO;

// --- 辅助函数实现 ---

static void showDebugLog(NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!debugLabel) {
            debugLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, [UIScreen mainScreen].bounds.size.width - 40, 120)];
            debugLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
            debugLabel.textColor = [UIColor whiteColor];
            debugLabel.numberOfLines = 0;
            debugLabel.font = [UIFont systemFontOfSize:10];
            debugLabel.layer.cornerRadius = 8;
            debugLabel.layer.masksToBounds = YES;
            debugLabel.userInteractionEnabled = YES;
            
            UIWindow *window = [UIApplication sharedApplication].keyWindow ?: [[UIApplication sharedApplication].windows firstObject];
            [window addSubview:debugLabel];
        }
        debugLabel.text = [NSString stringWithFormat:@"%@\n%@", message, debugLabel.text ?: @""];
    });
}

static void showAlert(NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        UIWindow *window = [UIApplication sharedApplication].keyWindow ?: [[UIApplication sharedApplication].windows firstObject];
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// 视频选择逻辑
static void handleVideoSelection(NSString *videoName) {
    showDebugLog([NSString stringWithFormat:@"选择: %@", videoName]);
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    selectedVideoPath = [documentsPath stringByAppendingFormat:@"/Videos/%@.mp4", videoName];
    isVideoReplaceEnabled = YES;
}

static void showVideoSelectionMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"虚拟相机控制" message:@"选择视频文件" preferredStyle:UIAlertControllerStyleAlert];
        NSArray *videos = @[@"视频1", @"视频2", @"视频3"];
        for (NSString *v in videos) {
            [alert addAction:[UIAlertAction actionWithTitle:v style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                handleVideoSelection(v);
            }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"关闭插件" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            isVideoReplaceEnabled = NO;
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow ?: [[UIApplication sharedApplication].windows firstObject];
        UIViewController *top = window.rootViewController;
        while (top.presentedViewController) top = top.presentedViewController;
        [top presentViewController:alert animated:YES completion:nil];
    });
}

// --- Hook 核心部分 ---

%hook AVCaptureDevice
+ (id)deviceWithUniqueID:(id)arg1 {
    if (isVideoReplaceEnabled && selectedVideoPath) {
        showDebugLog(@"[!] 尝试拦截摄像头...");
    }
    return %orig;
}
%end

%hook UIViewController

%new
- (void)handlePan:(UIPanGestureRecognizer *)pan {
    UIView *view = pan.view;
    CGPoint translation = [pan translationInView:view.superview];
    view.center = CGPointMake(view.center.x + translation.x, view.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:view.superview];
}

%new
- (void)tapViewTapped:(UITapGestureRecognizer *)gestureRecognizer {
    showVideoSelectionMenu();
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    currentViewController = self;
    if (!hasShownInitialAlert) {
        hasShownInitialAlert = YES;
        showDebugLog(@"插件注入成功！点击顶部触发菜单");
        
        // 创建点击区域
        UIWindow *window = [UIApplication sharedApplication].keyWindow ?: [[UIApplication sharedApplication].windows firstObject];
        UIView *tapView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, window.bounds.size.width, 44)];
        tapView.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.1];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapViewTapped:)];
        [tapView addGestureRecognizer:tap];
        [window addSubview:tapView];
    }
}
%end

%ctor {
    NSLog(@"[VirtualCamera] Loaded");
}
