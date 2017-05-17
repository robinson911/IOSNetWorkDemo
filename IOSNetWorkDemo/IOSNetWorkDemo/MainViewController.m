//
//  MainViewController.m
//  IOSNetWorkDemo
//
//  Created by 孙伟伟 on 16/7/30.
//  Copyright © 2016年 孙伟伟. All rights reserved.
//

#import "MainViewController.h"
#import "AppDelegate.h"
#import "NSURLSessionViewController.h"
#import "NSURLViewController.h"
#import "NSStreamViewController.h"

@interface MainViewController ()<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,strong) NSDictionary *items;

@end

@implementation MainViewController

/*#pragma mark -- life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"网络Demo";
    
    [self initContent];
}

#pragma mark -- init

- (void)initContent
{
    UIButton *_requestURLBtn = [[UIButton alloc]initWithFrame:CGRectMake(15, 100, kDEVICEWIDTH - 30, 45)];
    _requestURLBtn.backgroundColor = [UIColor grayColor];
    [_requestURLBtn addTarget:self action:@selector(netClick:) forControlEvents:UIControlEventTouchUpInside];
    _requestURLBtn.tag = 999;
    [_requestURLBtn setTitle:@"NSURL网络请求" forState:UIControlStateNormal];
    _requestURLBtn.titleLabel.textColor = [UIColor whiteColor];
    _requestURLBtn.layer.cornerRadius = 4;
    [self.view addSubview:_requestURLBtn];
    
    UIButton *_requestURLSessionBtn = [[UIButton alloc]initWithFrame:CGRectMake(15, 220, kDEVICEWIDTH - 30, 45)];
    _requestURLSessionBtn.backgroundColor = [UIColor grayColor];
    [_requestURLSessionBtn addTarget:self action:@selector(netClick:) forControlEvents:UIControlEventTouchUpInside];
    _requestURLSessionBtn.tag = 1000;
    [_requestURLSessionBtn setTitle:@"NSURLSession网络请求" forState:UIControlStateNormal];
    _requestURLSessionBtn.titleLabel.textColor = [UIColor whiteColor];
    _requestURLSessionBtn.layer.cornerRadius = 4;
    [self.view addSubview:_requestURLSessionBtn];
    
    UIButton *_requestNSStreamBtn = [[UIButton alloc]initWithFrame:CGRectMake(15, 340, kDEVICEWIDTH - 30, 45)];
    _requestNSStreamBtn.backgroundColor = [UIColor grayColor];
    [_requestNSStreamBtn addTarget:self action:@selector(netClick:) forControlEvents:UIControlEventTouchUpInside];
    _requestNSStreamBtn.tag = 1001;
    [_requestNSStreamBtn setTitle:@"NSStream网络请求" forState:UIControlStateNormal];
    _requestNSStreamBtn.titleLabel.textColor = [UIColor whiteColor];
    _requestNSStreamBtn.layer.cornerRadius = 4;
    [self.view addSubview:_requestNSStreamBtn];
}

#pragma mark -- clicked function

- (void)netClick:(id)sender
{
    UIButton *btn = (UIButton*)sender;
    NSInteger tag = btn.tag;
    
   
    if (tag == 999)
    {
        NSURLViewController *_vc = [[NSURLViewController alloc]init];
        
        [self.navigationController pushViewController:_vc animated:NO];

    }
    else if (tag == 1000)
    {
        NSURLSessionViewController *_vc = [[NSURLSessionViewController alloc]init];
        
        [self.navigationController pushViewController:_vc animated:NO];
    }
    
    else if (tag == 1001)
    {
        NSStreamViewController *_vc = [[NSStreamViewController alloc]init];
        
        [self.navigationController pushViewController:_vc animated:NO];
    }
}

@end*/


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"网络Demo";
    
    _items = @{
               @"NSURL Demo": @"NSURLViewController",
               @"NSURLSession Demo": @"NSURLSessionViewController",
               @"NSStream Demo" : @"NSStreamViewController"
               };
    
    UITableView *_mainTableView = [[UITableView alloc]init];
    [_mainTableView setFrame:CGRectMake(0, 0, kDEVICEWIDTH, kDEVICEHEIGHT)];
    _mainTableView.dataSource = self;
    _mainTableView.delegate = self;
    [self.view addSubview:_mainTableView];
}

- (id) keyInDictionary:(NSDictionary *)dict atIndex:(NSInteger)index
{
    NSArray * keys = [dict allKeys];
    if (index >= [keys count])
    {
        NSLog(@" >> Error: index out of bounds. %s", __FUNCTION__);
        return nil;
    }
    
    return keys[index];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"NetworkCellIdentifier";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSString * key = [self keyInDictionary:_items atIndex:indexPath.row];
    cell.textLabel.text = key;
    
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * key = [self keyInDictionary:_items atIndex:indexPath.row];
    NSString * controllerName = [_items objectForKey:key];
    
    Class controllerClass = NSClassFromString(controllerName);
    if (controllerClass != nil)
    {
        id controller = [[controllerClass alloc] init];
        [self.navigationController pushViewController:controller animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

