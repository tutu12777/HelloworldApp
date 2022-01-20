/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
//  ViewController.m
//  HelloWorldApp
//

#import "ViewController.h"
//#import "BViewController.h"
typedef void(^clickBlock)();
@interface ViewController ()
@property (nonatomic, strong) NSTimer *tiemr;
@property (nonatomic, copy) clickBlock block;
@property (nonatomic, copy) clickBlock block1;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    UIButton *test = [UIButton new];
    [test setFrame:CGRectMake(20, 20, 100, 50)];
    [test setTitle:@"测试" forState:UIControlStateNormal];
    [self.view addSubview:test];
    [test addTarget:self action:@selector(testAction) forControlEvents:UIControlEventTouchUpInside];
//    [test setTitle:@"测试" forState:UIControlStateNormal];
  // Do any additional setup after loading the view, typically from a nib.
    self.block = ^(){
        [self testTimer];
    };
}

- (void)testTimer {
    NSLog(@"testTimer11111");
    self.block1 = ^{
        [self testAction];
    }
}

//sdk国密，接口，（监控，埋点）
//老的版本有可能无法支持，放量到1.0，实现，inside改造
//老容器，老方法，新容器， 新需求接新容器， 老需求有改动就接新容器，

//
//如何切， 如何改， 新容器强升  1.0 2.0 3.0  每个容器
//调用方法， 回调方式不一样
//百信贷
//

- (void)testAction {
    NSLog(@"testAction11111");
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
