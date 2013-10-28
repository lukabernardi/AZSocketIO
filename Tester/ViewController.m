//
//  ViewController.m
//  Tester
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright 2012 Patrick Shields
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    __weak ViewController *blockSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [blockSelf setupConn];
                                                  }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupConn];
}

- (void)setupConn
{
    __weak ViewController *blockSelf = self;
    self.socket = [[AZSocketIO alloc] initWithHost:@"localhost" andPort:@"9000" secure:NO];
    //socket.transports = [NSMutableSet setWithObject:@"xhr-polling"];
    [self.socket setEventReceivedBlock:^(NSString *eventName, id data) {
        blockSelf.name.text = eventName;
        blockSelf.args.text = [data description];
        [NSTimer scheduledTimerWithTimeInterval:1 target:blockSelf selector:@selector(sendTime) userInfo:nil repeats:NO];
    }];
    [self.socket connectWithSuccess:^{
        NSLog(@"Hurray");
    } andFailure:^(NSError *error) {
        NSLog(@"Boo: %@", error);
    }];
}

- (void)sendTime
{
    [self.socket send:[[NSDate new] description] error:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
