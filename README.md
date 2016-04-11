# meshblu-npm

[![Build Status](https://travis-ci.org/octoblu/meshblu-npm.svg?branch=master)](https://travis-ci.org/octoblu/meshblu-npm)
[![Code Climate](https://codeclimate.com/github/octoblu/meshblu-npm/badges/gpa.svg)](https://codeclimate.com/github/octoblu/meshblu-npm)
[![Test Coverage](https://codeclimate.com/github/octoblu/meshblu-npm/badges/coverage.svg)](https://codeclimate.com/github/octoblu/meshblu-npm)

A network and realtime API for enabling machine-to-machine communications.

[Screencast 1: What is Skynet?](http://www.youtube.com/watch?v=cPs1JNFyXjk)

[Documentation](https://meshblu.readme.io/v1.0)

[What is Octoblu?](https://octoblu-designer.readme.io/)


Example

Require Meshblu

```js
var Meshblu = require('meshblu');
```

Register device with cUrl
```bash
curl -X POST -d "type=example" http://meshblu.octoblu.com/devices
```

response
```json
{
  "type":"example",
  "discoverWhitelist":["*"],
  "configureWhitelist":["*"],
  "sendWhitelist":["*"],
  "receiveWhitelist":["*"],
  "uuid":"a28f068b-f19f-4f7b-9cf6-7c3d36c8aa14",
  "online":false,
  "token":"dcb61b31d2497da629ee33a9ac20cf397e24d093",
  "meshblu":{
    "createdAt":"2016-04-11T21:20:41+00:00",
    "hash":"oQW/46H1UeC7+1QyDIy6wm5SGYiIgVMKxkVRK623DMY="}}
```
Create Connection with UUID/TOKEN
```js
var conn = Meshblu.createConnection({
  "uuid": "a28f068b-f19f-4f7b-9cf6-7c3d36c8aa14",
  "token": "dcb61b31d2497da629ee33a9ac20cf397e24d093",
  "server": "meshblu.octoblu.com",
  "port": 443
});
```

Not Ready
```js
conn.on('notReady', function(data){
  console.log('UUID FAILED AUTHENTICATION!');
  console.log(data);
});
```

On Ready
```js
conn.on('ready', function(data){
  console.log('UUID AUTHENTICATED!');
  console.log(data);
});
```

Send Message
```js
  conn.message({
    "devices": "*",
    "payload": {
      "meshblu":"online"
    }
  });
```

On Message
```js
  conn.on('message', function(message){
    console.log('message received', message);
  });
```

Subscribe
```js
  // Subscribe to device
  conn.subscribe({
    "uuid": "f828ef20-29f7-11e3-9604-b360d462c699",
    "token": "syep2lu2d0io1or305llz5u9ijrwwmi"
  }, function (data) {
    console.log(data);
  });
```

Unsubscribe
```js
  // Subscribe to device
  conn.unsubscribe({
    "uuid": "f828ef20-29f7-11e3-9604-b360d462c699"
  }, function (data) {
    console.log(data);
  });  
```

On Disconnect
```js
  conn.on('disconnect', function(data){
    console.log('disconnected from meshblu');
  });
```

Register Device
```js
  conn.register({
    "type": "drone"
  }, function (data) {
    console.log(data);
  });
```

Unregister Device
```js
  conn.unregister({
    "uuid": "",
    "token": ""
  }, function (data) {
    console.log(data);
  });
```

Update
```js
  conn.update({
    "uuid":"",
    "token": "",
    "armed":true
  }, function (data) {
    console.log(data);
  });
```

On Config
```js
  conn.on('config', function(data){
    console.log('device updated', data);
  });
```

Whoami
```js
  conn.whoami({"uuid":""}, function (data) {
    console.log(data);
  });
```

Search Devices
```js
  conn.devices({
    "type":"drone"
  }, function (data) {
    console.log(data);
  });
```

Meshblu status
```js
  conn.status(function (data) {
    console.log(data);
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
