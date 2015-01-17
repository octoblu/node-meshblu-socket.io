# meshblu-npm

[![Build Status](https://travis-ci.org/octoblu/meshblu-npm.svg?branch=master)](https://travis-ci.org/octoblu/meshblu-npm)
[![Code Climate](https://codeclimate.com/github/octoblu/meshblu-npm/badges/gpa.svg)](https://codeclimate.com/github/octoblu/meshblu-npm)
[![Test Coverage](https://codeclimate.com/github/octoblu/meshblu-npm/badges/coverage.svg)](https://codeclimate.com/github/octoblu/meshblu-npm)

Phase 1 - Build a network and realtime API for enabling machine-to-machine communications.

Here are several quick screencasts that demostrate what you can do with Skynet:

[Screencast 1: What is Skynet?](http://www.youtube.com/watch?v=cPs1JNFyXjk)

[Screencast 2: Introducing an Arduino](http://www.youtube.com/watch?v=SzaTPiaDDQI)

[Screencast 3: Security device tokens added](http://www.youtube.com/watch?v=TB6RyzT10EA)

[Screencast 4: Node.JS NPM module released](http://www.youtube.com/watch?v=0WjNG6AOcXM)

[Screencast 5: PubSub feature added to device UUID channels](https://www.youtube.com/watch?v=SL_c1MSgMaw)

[Screencast 6: Events endpoint added to APIs](https://www.youtube.com/watch?v=GJqSabO1EUA)


Example

```
var skynet = require('skynet');

var conn = skynet.createConnection({
  "uuid": "ad698900-2546-11e3-87fb-c560cb0ca47b",
  "token": "zh4p7as90pt1q0k98fzvwmc9rmjkyb9",
  "protocol": "mqtt", // or "websocket"
  "qos": 0, // MQTT Quality of Service (0=no confirmation, 1=confirmation, 2=N/A)
  "server": "localhost", // optional - defaults to ws://meshblu.octoblu.com
  "port": 3000  // optional - defaults to 80
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
  conn.message({
    "devices": "*",
    "payload": {
      "skynet":"online"
    },
    "qos": 0
  });
  conn.message({
    "devices": "0d3a53a0-2a0b-11e3-b09c-ff4de847b2cc",
    "payload": {
      "skynet":"online"
    },
    "qos": 0
  });
  conn.message({
    "devices": ["0d3a53...847b2cc", "11123...44567"],
    "payload": {
      "skynet":"online"
    },
    "qos": 0
  });

  conn.on('message', function(channel, message){
    console.log('message received', channel, message);
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

LICENSE
-------

(MIT License)

Copyright (c) 2014 Octoblu <info@octoblu.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
