//
//  ViewController.m
//  JsCallOCDemo
//
//  Created by admin on 2017/9/18.
//  Copyright © 2017年 admin. All rights reserved.
//

#import "ViewController.h"
#import "WebViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    WebViewController *web = [[WebViewController alloc] init];
    [self.navigationController pushViewController:web animated:YES];
}

@end
