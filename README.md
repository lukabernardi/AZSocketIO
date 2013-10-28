AZSocketIO
==========
AZSocketIO is a socket.io client for iOS. It:

* Supports websockets and xhr-polling transports
* Supports namespacing a socket
* Is about alpha stage
* Is heavily reliant on blocks for it's API
* Has appledocs for all user facing classes
* Welcomes patches and issues

Dependencies
------------
AZSocketIO uses cocoapods, so you shouldn't have to think too much about dependencies, but here they are.

* [SocketRocket](https://github.com/square/SocketRocket)

AZSocketIO uses NSURLSession, so it's iOS 7+.

Usage
-----
``` objective-c
AZSocketIO *socket = [[AZSocketIO alloc] initWithHost:@"localhost" andPort:@"9000"];
[socket setEventReceivedBlock:^(NSString *eventName, id data) {
    NSLog(@"%@ : %@", eventName, data);
}];
[socket connectWithSuccess:^{
	[socket emit:@"Send Me Data" args:@"cows" error:nil];
} andFailure:^(NSError *error) {
    NSLog(@"Boo: %@", error);
}];
```

Author
-------
Pat Shields

* http://github.com/pashields
* http://twitter.com/whatidoissecret

Contributors
------------
* Luca Bernardi (https://github.com/lukabernardi)
* Oli Kingshott (https://github.com/oliland)

License
-------
Apache 2.0
