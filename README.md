```
 SSSSS  kk                            tt    
SS      kk  kk yy   yy nn nnn    eee  tt    
 SSSSS  kkkkk  yy   yy nnn  nn ee   e tttt  
     SS kk kk   yyyyyy nn   nn eeeee  tt    
 SSSSS  kk  kk      yy nn   nn  eeeee  tttt 
                yyyyy                         
```

Phase 1 - Build a network and realtime API for enabling machine-to-machine communications.

Here are several quick screencasts that demostrate what you can do with Skynet:

[Screencast 1: What is Skynet?](http://www.youtube.com/watch?v=cPs1JNFyXjk)

[Screencast 2: Introducing an Arduino](http://www.youtube.com/watch?v=SzaTPiaDDQI)

[Screencast 3: Security device tokens added](http://www.youtube.com/watch?v=TB6RyzT10EA)

[Screencast 4: Node.JS NPM module released](http://www.youtube.com/watch?v=0WjNG6AOcXM)

[Screencast 5: PubSub feature added to device UUID channels](https://www.youtube.com/watch?v=SL_c1MSgMaw)


Example

```
var skynet = require('skynet');

var conn = skynet.createConnection({
  "host":"localhost",
  "port": 3000,
  "uuid": "ad698900-2546-11e3-87fb-c560cb0ca47b",
  "token": "zh4p7as90pt1q0k98fzvwmc9rmjkyb9"
});

conn.on('notReady', function(data){
  console.log('UUID FAILED AUTHENTICATION!');
  console.log(data);
});

conn.on('ready', function(data){
  console.log('UUID AUTHENTICATED!');
  console.log(data);

  // Subscribe to device
  conn.subscribe({
    "uuid": "f828ef20-29f7-11e3-9604-b360d462c699",
    "token": "syep2lu2d0io1or305llz5u9ijrwwmi"
  }, function (data) {
    console.log(data); 
  });

  // Subscribe to device
  conn.unsubscribe({
    "uuid": "f828ef20-29f7-11e3-9604-b360d462c699"
  }, function (data) {
    console.log(data); 
  });  

  // Send and receive messages
  conn.send({
    "devices": "all",
    "message": {
      "skynet":"online"
    }
  });

  conn.on('message', function(data){
    console.log('status received');
    console.log(data);
  });

  // Event triggered when device loses connection to skynet
  conn.on('disconnect', function(data){
    console.log('disconnected from skynet');
  });

  // Register a device (note: you can leave off the token to have skynet generate one for you)
  conn.register({
    "token": "zh4p7as90pt1q0k98fzvwmc9rmjkyb9", 
    "type": "drone"
  }, function (data) {
    console.log(data); 
  });

  // UnRegister a device
  conn.unregister({
    "uuid": "zh4p7as90pt1q0k98fzvwmc9rmjkyb9", 
    "token": "zh4p7as90pt1q0k98fzvwmc9rmjkyb9"
  }, function (data) {
    console.log(data); 
  });


  // Update device
  conn.update({
    "uuid":"ad698900-2546-11e3-87fb-c560cb0ca47b", 
    "token": "zh4p7as90pt1q0k98fzvwmc9rmjkyb9", 
    "armed":true
  }, function (data) {
    console.log(data); 
  });

  // WhoAmI?
  conn.whoami({"uuid":"ad698900-2546-11e3-87fb-c560cb0ca47b"}, function (data) {
    console.log(data); 
  });

  // Receive an array of device UUIDs based on user defined search criteria
  conn.devices({
    "type":"drone"
  }, function (data) {
    console.log(data); 
  });

  // Skynet status
  conn.status(function (data) {
    console.log(data); 
  });

});



```
