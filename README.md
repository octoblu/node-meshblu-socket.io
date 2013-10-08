```
 SSSSS  kk                            tt    
SS      kk  kk yy   yy nn nnn    eee  tt    
 SSSSS  kkkkk  yy   yy nnn  nn ee   e tttt  
     SS kk kk   yyyyyy nn   nn eeeee  tt    
 SSSSS  kk  kk      yy nn   nn  eeeee  tttt 
                yyyyy                         
```
======

Phase 1 - Build a network and realtime API for enabling machine-to-machine communications.

Here are several quick screencasts that demostrate what you can do with Skynet:

[POC Video 1](http://www.youtube.com/watch?v=cPs1JNFyXjk)

[POC Video 2](http://www.youtube.com/watch?v=SzaTPiaDDQI)

[POC Video 3](http://www.youtube.com/watch?v=TB6RyzT10EA)

Example
#######

```
var skynet = require('skynet');

var conn = skynet.createConnection({
  "host":"localhost",
  "port": 3000,
  "uuid": "ad698900-2546-11e3-87fb-c560cb0ca47b",
  "token": "zh4p7as90pt1q0k98fzvwmc9rmjkyb9"
});


conn.on('message', function(data){
  console.log('status received');
  console.log(data);
});

conn.send({
  "devices": "all",
  "message": {
    "contra":"is cool"
  }
});
```
