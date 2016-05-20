# node-meshblu-socket.io

[![Build Status](https://travis-ci.org/octoblu/node-meshblu-socket.io.svg?branch=master)](https://travis-ci.org/octoblu/node-meshblu-socket.io)
[![Code Climate](https://codeclimate.com/github/octoblu/meshblu-npm/badges/gpa.svg)](https://codeclimate.com/github/octoblu/meshblu-npm)
[![Test Coverage](https://codeclimate.com/github/octoblu/meshblu-npm/badges/coverage.svg)](https://codeclimate.com/github/octoblu/meshblu-npm)

A client side library for using the [Meshblu Socket.IO API](https://meshblu-socketio.readme.io/) in [Node.js](https://nodejs.org)

# Table of Contents

* [Getting Started](#getting-started)
  * [Install](#install)
  * [Quick Start](#quick-start)
* [Events](#events)
  * [Event: "ready"](#event-ready)
  * [Event: "notReady"](#event-notready)
* [Methods](#methods)
  * [createConnection(options)](#createconnectionoptions)
  * [conn.device(query, callback)](#conndevicequery-callback)
  * [conn.devices(query, callback)](#conndevicesquery-callback)
  * [conn.generateAndStoreToken(query, callback)](#conngenerateandstoretokenquery-callback)
  * [conn.message(message)](#connmessagemessage)

# Getting Started

## Install

The Meshblu client-side library is best obtained through NPM:

```shell
npm install --save meshblu
```

Alternatively, a browser version of the library is available from https://cdn.octoblu.com/js/meshblu/latest/meshblu.bundle.js. This exposes a global object on `window.meshblu`.

```html
<script type="text/javascript" src="https://cdn.octoblu.com/js/meshblu/latest/meshblu.bundle.js" ></script>
```

## Quick Start

The client side library establishes a secure socket.io connection to Meshblu at `https://meshblu-socket-io.octoblu.com` by default.

```javascript
var meshblu = require('meshblu');
var conn = meshblu.createConnection({
  uuid: '78159106-41ca-4022-95e8-2511695ce64c',
  token: 'd5265dbc4576a88f8654a8fc2c4d46a6d7b85574'
});
conn.on('ready', function(){
  console.log('Ready to rock');
});
```

# Events

## Event: "ready"

* `response` Response of a successful authentication.
  * `uuid` UUID of the device the connection is authenticated as.
  * `token` Plain-text token of the device the connection is authenticated as. The `token` is passed through by the API so that it can be returned here, it is never stored as plain text by Meshblu.
  * *(deprecated)* `api` A legacy identifier kept for backwards compatibility. Should not be used in any new projects.
  * *(deprecated)* `status` A legacy status code kept for backwards compatibility. Should not be used in any new projects.

##### Note

The `"ready"` event is emitted every time the connection is re-established. In normal network conditions, it is not uncommon the connection to occasionally drop and reestablish itself. In those cases, the library will re-authenticate and the brief outage will not be noticeable. Two things to note:

* Messages sent to the device while it is reconnecting will not be delivered to the client.
* Setting event listeners inside of the callback to the `"ready"` event is discouraged as they will be doubled up every time the event is fired. This may lead to functions being unexpectedly called multiple times for a single event. It presents itself as erratic behavior that appears to only happen after the connection has been established for a long time, and can therefore be very difficult to track down.

##### Example

```javascript
conn.on('ready', function(response){
  console.log('ready');
  console.log(JSON.stringify(response, null, 2));
  // ready
  // {
  //   "uuid": "78159106-41ca-4022-95e8-2511695ce64c",
  //   "token": "d5265dbc4576a88f8654a8fc2c4d46a6d7b85574",
  //   "api": "connect",
  //   "status": 201
  // }
});
```

## Event: "notReady"

* `response` Response of a failed authentication attempt.
  * `uuid` UUID of the device the connection attempted to authenticated as.
  * `token` Plain-text token of the device the connection attempted to authenticate as. The `token` is passed through by the API so that it can be returned here, it is never stored as plain text by Meshblu.
  * *(deprecated)* `api` A legacy identifier kept for backwards compatibility. Should not be used in any new projects.
  * *(deprecated)* `status` A legacy status code kept for backwards compatibility. Should not be used in any new projects.

##### Example

```javascript
conn.on('notReady', function(response){
  console.error('notReady');
  console.error(JSON.stringify(response, null, 2));
  // notReady
  // {
  //   "uuid": "i-made-this-uuid-up",
  //   "token": "i-made-this-token-up",
  //   "api": "connect",
  //   "status": 401
  // }
});
```

# Methods

## createConnection(options)

Establishes a socket.io connection to meshblu and returns the connection object.

##### Arguments

* `options` connection options with the following keys:
  * `server` The hostname of the Meshblu server to connect to. (Default: `meshblu-socket-io.octoblu.com`)
  * `port` The port of the Meshblu server to connect to. (Default: `443`)
  * `uuid` UUID of the device to connect with.
  * `token` Token of the device to connect with.

##### Note

If the `uuid` and `token` options are omitted, Meshblu will create a new device when the connection is established and emit a `ready` event with the device's credentials. This will be the only time that device's `token` is available as plain text. This auto device creation feature exists for backwards compatibility, its use in new projects is strongly discouraged.

##### Example

```javascript
var conn = meshblu.createConnection({
  server: 'meshblu-socket-io.octoblu.com'
  port: 443
  uuid: '78159106-41ca-4022-95e8-2511695ce64c',
  token: 'd5265dbc4576a88f8654a8fc2c4d46a6d7b85574'
});
```

## conn.device(query, callback)

Retrieve a device from the Meshblu device registry by its `uuid`. In order to retrieve a target device, your connection must be authenticated as a device that is in the target device's `discover.view` whitelist. See the [Meshblu whitelist documentation](https://meshblu.readme.io/docs/whitelists-2-0) for more information.

##### Arguments

* `query` Query object, must contain only the `uuid` property.
  * `uuid` UUID of the device to retrieve.
* `callback` Function that will be called with a `result`.
  * `result` Object passed to the callback. Contains either the `device` or `error` key, but never both.
    * `device` The full device record from the Meshblu registry.
    * `error` String explaining the what went wrong. Is only present if something went wrong.

##### Note

In Meshblu, it is not possible to distinguish between a device not existing and not having permission to view a device. In most of the Meshblu API calls, the error in both cases yields the protocol-specific equivalent of an `HTTP 404: Not Found`. The Socket.IO API, however, returns the error `Forbidden`. This is for backwards compatibility and will likely change with the next major version release of the Socket.IO API.

##### Example

When requesting a valid device that the authorized device may view:

```javascript
conn.device({uuid: '78159106-41ca-4022-95e8-2511695ce64c'}, function(result){
  console.log('device');
  console.log(JSON.stringify(result, null, 2));
  // device
  // {
  //   "device": {
  //     "meshblu": {
  //       "version": "2.0.0",
  //       "whitelists": {},
  //       "createdAt": "2016-05-19T23:28:08+00:00",
  //       "hash": "4ez1I/uziZVk7INf6n1un+op/oNsIDoFVs/MW/KGWMQ=",
  //       "updatedAt": "2016-05-20T16:07:57+00:00"
  //     },
  //     "uuid": "78159106-41ca-4022-95e8-2511695ce64c",
  //     "online": true
  //   }
  // }
});
```

When requesting a non-existing device, or a device the authenticated device may not view:

```javascript
conn.device({uuid: 'i-made-this-uuid-up'}, function(result){
  console.log('device');
  console.log(JSON.stringify(result, null, 2));
  // device
  // {
  //   "error": "Forbidden"
  // }
});
```

## conn.devices(query, callback)

Retrieve devices from the Meshblu device registry. In order to retrieve a target device, your connection must be authenticated as a device that is in the target device's `discover.view` whitelist. See the [Meshblu whitelist documentation](https://meshblu.readme.io/docs/whitelists-2-0) for more information.

##### Arguments

* `query` Query object, filters the device that will be returned. With the exception of the following special cases, properties are used as filters. For example, passing a query of `{color: 'red'}` will yield all devices that contain a color key with value 'red' that the authorized connetion has access to.
  * `online` If present, the value for `online` will be compared against the string "true", and the resulting boolean value will be used. *Note: using a boolean value of `true` will be evaluated as `false` because it is not equeal to "true"*.
  * `"null"` & `""` If any key is passed in with a value of the string `"null"` or the empty string `""`, it will retrieve only devices that do not contain the key at all.
* `callback` Function that will be called with a `result`.
  * `result` Object passed to the callback. Contains the `devices` key.
    * `devices` The devices retrieved from the Meshblu registry.

##### Example

When requesting valid devices that the authorized device may view:

```javascript
conn.devices({color: 'blue'}, function(result){
  console.log('devices');
  console.log(JSON.stringify(result, null, 2));
  // devices
  // {
  //   "devices": [
  //     {
  //       "color": "blue",
  //       "discoverWhitelist": [ "*" ],
  //       "uuid": "c30a7506-7a45-4fe1-ab51-c57afad7f41a"
  //     },
  //     {
  //       "color": "blue",
  //       "discoverWhitelist": [ "*" ],
  //       "uuid": "7a9475ea-a595-42a4-8928-0aeb677c4990"
  //     }
  //   ]
  // }
});
```

When requesting a non-existing devices, or devices the authenticated device may not view:

```javascript
conn.devices({color: 'i-made-this-color-up'}, function(result){
  console.log('devices');
  console.log(JSON.stringify(result, null, 2));
  // device
  // {
  //   "devices": []
  // }
});
```

## conn.generateAndStoreToken(query, callback)

Generate a session token for a device in the Meshblu device registry. In order to generate a token, your connection must be authenticated as a device that is in the target device's `configure.update` whitelist. See the [Meshblu whitelist documentation](https://meshblu.readme.io/docs/whitelists-2-0) for more information.

##### Arguments

* `query` Query object, must contain only the `uuid` property.
  * `uuid` UUID of the device to generate a token for.
* `callback` Function that will be called with a `result`.
  * `result` Object passed to the callback. Contains either the (`uuid`, `token`, `createdAt`) triplet, or `error` key, but never both.
    * `uuid` The uuid for which a token was generated.
    * `token` The token that was generated in plain-text form. *This is the only time that token will ever be shown. If it is not saved at this point, it can never be retreived*
    * `createdAt` An ISO 8601 timestamp for when the token was generated.
    * `error` String explaining the what went wrong. Is only present if something went wrong.

##### Note

In Meshblu, it is not possible to distinguish between a device not existing and not having permission to view a device. In most of the Meshblu API calls, the error in both cases yields the protocol-specific equivalent of an `HTTP 404: Not Found`. The Socket.IO API, however, returns the error `Forbidden`. This is for backwards compatibility and will likely change with the next major version release of the Socket.IO API.

##### Example

When generateAndStoreToken is called for a valid device that the authorized device may update:

```javascript
conn.generateAndStoreToken({uuid: '78159106-41ca-4022-95e8-2511695ce64c'}, function(result){
  console.log('generateAndStoreToken');
  console.log(JSON.stringify(result, null, 2));
  // generateAndStoreToken
  // {
  //   "uuid": "78159106-41ca-4022-95e8-2511695ce64c",
  //   "createdAt": "2016-05-20T18:25:13.587Z",
  //   "token": "8234f58b65ff042da60d84af4230d3692778ca5b"
  // }
});
```

When generateAndStoreToken is called for a non-existing devices, or devices the authenticated device may not update:

```javascript
conn.generateAndStoreToken({uuid: 'i-made-this-uuid-up'}, function(result){
  console.log('generateAndStoreToken');
  console.log(JSON.stringify(result, null, 2));
  // generateAndStoreToken
  // {
  //   "error": "Forbidden"
  // }
});
```

## conn.message(message)

Send a message to one or more Meshblu devices. In order to send a device a message, the connection must be authenticated as a device that is in the recipient's `message.from` whitelist. See the [Meshblu whitelist documentation](https://meshblu.readme.io/docs/whitelists-2-0) for more information.

##### Arguments

* `message` Message object, must contain only the `devices` property. `topic` is treated special by Meshblu. Other properties are forwarded to the recipient(s), but Meshblu does not act on them in any way.
  * `devices` Array of UUIDs of devices to send the message to. If any of the UUIDs are the special string `"*"`, then the message will also be emitted as a `broadcast` message, and can be picked up by anyone in the emitter's `broadcast.sent` whitelist.
  * `topic` If the topic is provided as a string and the message is broadcast, the topic can be used by subscribers to filter incoming messages server-side.

##### Note

Meshblu does not currently provide any receipt confirmation natively. If a message is sent to an offline recipient that has no [message forwarding](https://meshblu.readme.io/docs/what-are-forwarders) or [device subscriptions](https://meshblu.readme.io/docs/how-subscriptions-work), the message will be dropped. If it is important to know when the recipient received a message, it is recommended to have the recipient send some form of acknowledgement message back.

##### Example

To send a direct message.

```javascript
conn.message({
  devices: ['78159106-41ca-4022-95e8-2511695ce64c'],
  topic: 'greeting',
  data: {
    howdy: 'partner'
  }
});
```

To send a broadcast message.

```javascript
conn.message({
  devices: ['*'],
  topic: 'exclamation',
  data: {
    feeling: 'good'
  }
});
```

To send a message that is simultaneously broadcast and sent directly to a device.

```javascript
conn.message({
  devices: ['*', '78159106-41ca-4022-95e8-2511695ce64c'],
  topic: 'recommendation',
  data: {
    guys: '78159106-41ca-4022-95e8-2511695ce64c is a pretty awesome dude!'
  }
});
```
