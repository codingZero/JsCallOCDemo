//
//  CHTrainDetailViewController.m
//  cuihua
//
//  Created by admin on 2017/7/13.
//  Copyright © 2017年 macbook. All rights reserved.
//

#import "WebViewController.h"
#import <WebKit/WebKit.h>
#import "UIView+Extension.h"


#define SCREEN_BOUNDS [UIScreen mainScreen].bounds
#define SCREEN_WIDTH SCREEN_BOUNDS.size.width
#define SCREEN_HEIGHT SCREEN_BOUNDS.size.height

@interface WebViewController ()<WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) WKWebView *wkWebView;
@property (strong, nonatomic) UIView *progressView;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UIView *leftBarItemView;
@property (nonatomic, weak) UIButton *closeButton;
@property (assign, nonatomic) BOOL backButtonClicked;
@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"测试";

    [self setupView];

    self.automaticallyAdjustsScrollViewInsets = NO;
    NSString *str = [[NSBundle mainBundle] pathForResource:@"test.html" ofType:nil];
    NSURL *url = [NSURL fileURLWithPath:str];
    [self.wkWebView loadFileURL:url allowingReadAccessToURL:url];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.progressView.width == 0 && !self.progressView.hidden) {
        [UIView animateWithDuration:.25 animations:^{
            self.progressView.width = self.view.width * 0.1;
        }];
    }
}


- (void)setupView {
    // 进度条
    UIView *progressView = [[UIView alloc] init];
    progressView.backgroundColor = [UIColor redColor];
    progressView.y = 64;
    progressView.height = 2;
    [self.view addSubview:progressView];
    self.progressView = progressView;
    
    // 网页
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    config.userContentController = [WKUserContentController new];
    //注入对象
    [config.userContentController addScriptMessageHandler:self name:@"ocModel"];
    
    WKWebView *wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 64, SCREEN_WIDTH, SCREEN_HEIGHT - 64) configuration:config];
    wkWebView.scrollView.showsVerticalScrollIndicator = NO;
    wkWebView.scrollView.showsHorizontalScrollIndicator = NO;
    wkWebView.allowsBackForwardNavigationGestures = YES;
    wkWebView.navigationDelegate = self;
    wkWebView.UIDelegate = self;
    [self.view insertSubview:wkWebView belowSubview:progressView];

    [wkWebView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    [wkWebView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    self.wkWebView = wkWebView;
}

- (void)openPhotoLibrary {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSData *data = UIImagePNGRepresentation(image);
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSString *imagePath = [path stringByAppendingPathComponent:@"photo.png"];
    [data writeToFile:imagePath atomically:YES];
    
    NSString *jsSelector = [NSString stringWithFormat:@"setImage(\"%@\")", imagePath];
    [self.wkWebView evaluateJavaScript:jsSelector completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        
    }];
}


- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *dic = message.body;
    NSString *type = dic[@"type"];
    if ([type isEqualToString:@"callSelector"]) {
        NSString *selName = dic[@"selector"];
        [self performSelector:NSSelectorFromString(selName)];
    } else if ([type isEqualToString:@"sendData"]) {
        NSString *title = dic[@"data"];
        self.title = title;
    }
}


- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *str = navigationAction.request.URL.absoluteString;
    if ([str hasPrefix:@"js:getIOSFunForH5:"]) {
        NSArray *param = [str componentsSeparatedByString:@"js:getIOSFunForH5:"];
        NSString *paramStr = [param.lastObject stringByRemovingPercentEncoding];
        NSData *data = [paramStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"%@", dic);
    } else if ([str containsString:@"www.baidu.com"]) {
        //如果是百度，不允许直接跳转
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL options:@{} completionHandler:^(BOOL success) {
            NSLog(@"%d", success);
        }];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}


- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        completionHandler();
    }];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:prompt preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    
    
    [self presentViewController:alertController animated:YES completion:nil];
}

// 计算wkWebView进度条
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        CGFloat newprogress = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
        self.progressView.hidden = NO;
        [UIView animateWithDuration:.25 animations:^{
            self.progressView.width = self.view.width * newprogress;
        } completion:^(BOOL finished) {
            if (newprogress == 1.0) {
                self.progressView.width = 0;
                self.progressView.hidden = YES;
            }
        }];
    } else if ([keyPath isEqualToString:@"title"]) {
        self.navigationItem.title = self.wkWebView.title;
    }
}


// 记得取消监听
- (void)dealloc {
    if ([self isViewLoaded]) {
        [self.wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    }
    self.wkWebView.navigationDelegate = nil;
 
}

@end
