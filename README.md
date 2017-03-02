# node-meshblu-socket.io

[![Build Status](https://travis-ci.org/octoblu/node-meshblu-socket.io.svg?branch=master)](https://travis-ci.org/octoblu/node-meshblu-socket.io)
[![Code Climate](https://codeclimate.com/github/octoblu/meshblu-npm/badges/gpa.svg)](https://codeclimate.com/github/octoblu/meshblu-npm)
[![Test Coverage](https://codeclimate.com/github/octoblu/meshblu-npm/badges/coverage.svg)](https://codeclimate.com/github/octoblu/meshblu-npm)
[![Slack Status](http://community-slack.octoblu.com/badge.svg)](http://community-slack.octoblu.com)

[![NPM](https://nodei.co/npm/meshblu.svg?style=flat)](https://npmjs.org/package/meshblu)

A client side library for using the [Meshblu Socket.IO API](https://meshblu-socketio.readme.io/) in [Node.js](https://nodejs.org)

# NOTICE: Major Version Release

Version 2.0.0 of this library introduces some major API changes that make it incompatible with many of the code samples external to this README. Notably, the library is now instantiated as a class instead of using a `createConnection` function, and the `connect` method must be called to establish a connection. If the old functionality is required, the latest version of the previous API was `1.34.1`. It is highly recommended that you update to `2.0.0`, as `1.x.x` will not be supported in the future.

# Table of Contents

* [Getting Started](#getting-started)
  * [Install](#install)
  * [Quick Start](#quick-start)
* [Events](#events)
  * [Event: "config"](#event-config)
  * [Event: "message"](#event-message)
  * [Event: "notReady"](#event-notready)
  * [Event: "ready"](#event-ready)
* [Methods](#methods)
  * [constructor(options)](#constructoroptions)
  * [meshblu.connect(callback)](#meshbluconnectcallback)
  * [meshblu.device(query, callback)](#meshbludevicequery-callback)
  * [meshblu.devices(query, callback)](#meshbludevicesquery-callback)
  * [meshblu.generateAndStoreToken(query, callback)](#meshblugenerateandstoretokenquery-callback)
  * [meshblu.message(message)](#meshblumessagemessage)
  * [meshblu.register(params, callback)](#meshbluregisterparams-callback)
  * [meshblu.resetToken(query, callback)](#meshbluresettokenquery-callback)
  * [meshblu.revokeToken(auth, callback)](#meshblurevoketokenauth-callback)
  * [meshblu.subscribe(params)](#meshblusubscribeparams)
  * [meshblu.unregister(query, callback)](#meshbluunregisterquery-callback)
  * [meshblu.unsubscribe(params)](#meshbluunsubscribeparams)
  * [meshblu.update(query, callback)](#meshbluupdatequeryupdate-callback)
  * [meshblu.whoami(callback)](#meshbluwhoamicallback)

# Getting Started

## Install

The Meshblu client-side library is best obtained through NPM:

```shell
npm install --save meshblu
```

## Quick Start

The client side library establishes a secure socket.io connection to Meshblu at `https://meshblu-socket-io.octoblu.com` by default.

```javascript
var MeshbluSocketIO = require('meshblu');
var meshblu = new MeshbluSocketIO({
  resolveSrv: true,
  uuid: '78159106-41ca-4022-95e8-2511695ce64c',
  token: 'd5265dbc4576a88f8654a8fc2c4d46a6d7b85574'
})
meshblu.on('ready', function(){
  console.log('Ready to rock');
});
meshblu.connect();
```

# Events

## Event: "config"

The `config` event is emitted whenever a device is updated. Use the [`meshblu.subscribe`](#meshblusubscribeparams) API to subscribe to `config` events. In order to receive config events from a device, your connection must be authenticated as a device that is in the target device's `configure.sent` whitelist. See the [Meshblu whitelist documentation](https://meshblu.readme.io/docs/whitelists-2-0) for more information.

* `device` Meshblu device that was modified
  * `uuid` Uuid of the device that was modified

##### Example

```javascript
meshblu.on('config', function(device){
  console.log('on config');
  console.log(JSON.stringify(device, null, 2));
  // on config
  // {
  //   "meshblu": {
  //     "version": "2.0.0",
  //     "whitelists": {},
  //     "hash": "9OAPxo5Yq1oTYNi1szGVBBlg4xuIVni47k8JhHYlXFk="
  //     }
  //   },
  //   "uuid": "78159106-41ca-4022-95e8-2511695ce64c",
  //   "foo": "bar"
  // }
});

otherConn.update({uuid: '78159106-41ca-4022-95e8-2511695ce64c', foo: 'bar'});
```

## Event: "message"

The `message` event is emitted whenever a device sends or receives a message. Use the [`meshblu.subscribe`](#meshblusubscribeparams) API to subscribe to `message` events for a device. In order to receive broadcast from a device, your connection must be authenticated as a device that is in the target device's `broadcast.sent` whitelist. To receive message sent by a device, your connection must be in the target's `message.sent` whitelist. To receive messages from other devices, they must be in the authorized device's `message.from` whitelist. See the [Meshblu whitelist documentation](https://meshblu.readme.io/docs/whitelists-2-0) for more information.

* `message` Message object that was received.
  * `devices` Array of UUIDs to whom the message was sent. It will contain the string `"*"`, If the message was a broadcast.
  * `fromUuid` Uuid of the device that sent the message. Is set by Meshblu, so it can be trusted as long as it is verified that the message was received through Meshblu.

##### Example

```javascript
meshblu.on('message', function(message){
  console.log('on message');
  console.log(JSON.stringify(message, null, 2));
  // on message
  // {
  //   "devices": [
  //     "*"
  //   ],
  //   "foo": "bar",
  //   "fromUuid": "1f6d9e7b-059b-4c1a-b699-708948ad8e10"
  // }
});

otherConn.message({devices: ['*'], foo: 'bar'});
```

## Event: "notReady"

The `notReady` event is emitted when certain things go wrong. These include emitting invalid authentication information in response to the `identify` challenge.

* `response` Response of a failed authentication attempt.
  * `uuid` UUID of the device the connection attempted to authenticated as.
  * `token` Plain-text token of the device the connection attempted to authenticate as. The `token` is passed through by the API so that it can be returned here, it is never stored as plain text by Meshblu.
  * *(deprecated)* `api` A legacy identifier kept for backwards compatibility. Should not be used in any new projects.
  * *(deprecated)* `status` A legacy status code kept for backwards compatibility. Should not be used in any new projects.

##### Example

When an incorrect `identity` event is rejected by Meshblu

```javascript
meshblu.on('notReady', function(response){
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

## Event: "ready"

The `ready` event is emitted whenever the connection emits an `identity` and Meshblu accepts the credentials.

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

When a valid `identity` is accepted by Meshblu:

```javascript
meshblu.on('ready', function(response){
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

# Methods

## constructor(options)

Establishes a socket.io connection to meshblu and returns the connection object.

##### Arguments

* `options` connection options with the following keys:
  * `protocol` The protocol to use when connecting to the server. May not be passed in if `resolveSrv` is true. Must be one of ws/wss (Default `wss`)
  * `hostname` The hostname of the Meshblu server to connect to. May not be passed in if `resolveSrv` is true. (Default: `meshblu-socket-io.octoblu.com`)
  * `port` The port of the Meshblu server to connect to. May not be passed in if `resolveSrv` is true. (Default: `443`)
  * `service` The service for which to look up an SRV record for. May only be passed in if `resolveSrv` is false. (Default: `meshblu`)
  * `domain` The domain for which to look up an SRV record on. May only be passed in if `resolveSrv` is false. (Default: `octoblu.com`)
  * `secure` Enable transport layer encryption. May only be passed in if `resolveSrv` is false. (Default: true)
  * `resolveSrv` Enable automatic service resolution using the SRV records.
  * `uuid` UUID of the device to connect with.
  * `token` Token of the device to connect with.
  * `bufferRate` Rate to throttle commands send to Meshblu. (Default: 100)

##### Note

If the `uuid` and `token` options are omitted, Meshblu will create a new device when the connection is established and emit a `ready` event with the device's credentials. This will be the only time that device's `token` is available as plain text. This auto device creation feature exists for backwards compatibility, its use in new projects is strongly discouraged.

##### Example

```javascript
var MeshbluSocketIO = require('meshblu');
var conn = new MeshbluSocketIO({
  resolveSrv: true,
  uuid: '78159106-41ca-4022-95e8-2511695ce64c',
  token: 'd5265dbc4576a88f8654a8fc2c4d46a6d7b85574'
})
```

## meshblu.connect(callback)

Establish a socket.io connection to Meshblu.

##### Arguments

* `callback` Optional Function that will be called when the socket.io connection is established.
  * `error` Javascript error object when the connection failed. Will be undefined if no error occured.

##### Note

The callback is called once the socket.io connection is *connected*, but not yet *authorized*. All calls should wait until after the [ready event](#event-ready) has occurred.

##### Example


```javascript
meshblu.connect(function(error){
  console.log('connect');
  console.log(error);
  // connect
  // undefined
});
```

## meshblu.device(query, callback)

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
meshblu.device({uuid: '78159106-41ca-4022-95e8-2511695ce64c'}, function(result){
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
meshblu.device({uuid: 'i-made-this-uuid-up'}, function(result){
  console.log('device');
  console.log(JSON.stringify(result, null, 2));
  // device
  // {
  //   "error": "Forbidden"
  // }
});
```

## meshblu.devices(query, callback)

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
meshblu.devices({color: 'blue'}, function(result){
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
meshblu.devices({color: 'i-made-this-color-up'}, function(result){
  console.log('devices');
  console.log(JSON.stringify(result, null, 2));
  // device
  // {
  //   "devices": []
  // }
});
```

## meshblu.generateAndStoreToken(query, callback)

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
meshblu.generateAndStoreToken({uuid: '78159106-41ca-4022-95e8-2511695ce64c'}, function(result){
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
meshblu.generateAndStoreToken({uuid: 'i-made-this-uuid-up'}, function(result){
  console.log('generateAndStoreToken');
  console.log(JSON.stringify(result, null, 2));
  // generateAndStoreToken
  // {
  //   "error": "Forbidden"
  // }
});
```

## meshblu.message(message)

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
meshblu.message({
  devices: ['78159106-41ca-4022-95e8-2511695ce64c'],
  topic: 'greeting',
  data: {
    howdy: 'partner'
  }
});
```

To send a broadcast message.

```javascript
meshblu.message({
  devices: ['*'],
  topic: 'exclamation',
  data: {
    feeling: 'good'
  }
});
```

To send a message that is simultaneously broadcast and sent directly to a device.

```javascript
meshblu.message({
  devices: ['*', '78159106-41ca-4022-95e8-2511695ce64c'],
  topic: 'recommendation',
  data: {
    guys: '78159106-41ca-4022-95e8-2511695ce64c is a pretty awesome dude!'
  }
});
```

## meshblu.register(params, callback)

Register a new device with the Meshblu registry.

##### Arguments

* `params` A device object. May not include a `uuid` or `token`. All other properties will be saved to the device on creation. For a description of  the properties that will affect how Meshblu interacts with the device, see the [core Meshblu documentation](https://meshblu.readme.io/docs). If a `uuid` and/or `token` is provided, it will be ignored.
* `callback` Function that is called with a `device` on registration
  * `device` The newly registered Meshblu device. Make sure to save the `uuid` and `token`. The `token` will not be made available again as it is not stored in plain-text anywhere by Meshblu.

##### Note

The Socket.io implementation of Meshblu creates open devices using the old *(deprecated)* whitelists by default. This is to preserve backwards compatibility. It is strongly recommended to register devices with explicitly locked down [version 2.0.0 whitelists](https://meshblu.readme.io/docs/whitelists-2-0) instead by creating a v2.0.0 device (see the second example).

##### Example

To register a new (open) device

```javascript
meshblu.register({color: 'black'}, function(device){
  console.log('register');
  console.log(JSON.stringify(device, null, 2))
  // {
  //   "color": "black",
  //   "discoverWhitelist": [
  //     "*"
  //   ],
  //   "configureWhitelist": [
  //     "*"
  //   ],
  //   "sendWhitelist": [
  //     "*"
  //   ],
  //   "receiveWhitelist": [
  //     "*"
  //   ],
  //   "uuid": "5c7392dc-a4ba-4b5a-8c84-5934a3b3678b",
  //   "online": false,
  //   "token": "9e78f644a866e1b5b71d0a2dde912e8662477abf",
  //   "meshblu": {
  //     "createdAt": "2016-05-20T22:10:23+00:00",
  //     "hash": "kt8lmSb5r6ruHG41jqZZHp1CEQvzM1iMJ/kAUppryZo="
  //   }
  // }
});
```

To register a new closed device.

```javascript
meshblu.register({color: 'black', version: '2.0.0'}, function(device){
  console.log('register');
  console.log(JSON.stringify(device, null, 2))
  // {
  //   "color": "black",
  //   "uuid": "5c7392dc-a4ba-4b5a-8c84-5934a3b3678b",
  //   "online": false,
  //   "token": "9e78f644a866e1b5b71d0a2dde912e8662477abf",
  //   "meshblu": {
  //     "version": "2.0.0",
  //     "createdAt": "2016-05-20T22:10:23+00:00",
  //     "hash": "kt8lmSb5r6ruHG41jqZZHp1CEQvzM1iMJ/kAUppryZo="
  //   }
  // }
});
```

## meshblu.resetToken(query, callback)

Reset the root token of a device. This will revoke the existing root token,
generate a new one, and yield the generated token in the callback.

##### Arguments

* `query` Query object, must contain only the `uuid` property.
  * `uuid` UUID of the device to whose root token to reset
* `callback` Function that is called after the token has been revoked.
  * `response` Response object that wraps `device`
    * `device` The Meshblu device for which the token was reset. Contains only the `uuid` and `token` properties. Make sure to save the new `token`, it will not be made available again as it is not stored in plain-text anywhere by Meshblu.

##### Example

To reset a token for a device:

```javascript
meshblu.resetToken({uuid: '5c7392dc-a4ba-4b5a-8c84-5934a3b3678b'}, function(response){
  console.log('resetToken');
  console.log(JSON.stringify(device, null, 2));
  // resetToken
  // {
  //   "device": {
  //     "uuid": "2f9556ff-1084-4d4c-b131-5d3de42eff68",
  //     "token": "cc2f1fba8ffd7a46f4f414daf1011c2053e9a466"
  //   }
  // }
});
```

## meshblu.revokeToken(auth, callback)

Revoke a session token for a device

##### Arguments

* `auth` Authentication object, must contain only the `uuid` and `token` of the device to authenticate as.
  * `uuid` UUID of the device to whose token to revoke
  * `token` Token of the device to revoke
* `callback` Function that is called after the token has been revoked.

##### Example

To revoke a token for a device:

```javascript
meshblu.revokeToken({uuid: '5c7392dc-a4ba-4b5a-8c84-5934a3b3678b', token: '9e78f644a866e1b5b71d0a2dde912e8662477abf'}, function(){
  console.log('revokeToken');
});
```

## meshblu.subscribe(params)

Create a subscription to a device's messages. Subscribe tries to subscribe the connection to every message type. To limit subscriptions, use the `types` attribute.

##### Arguments

* `params`
  * `uuid` UUID of the device to subscribe to.
  * `types` Array of strings of types to subscribe to. Valid types are:
    * `broadcast` broadcast messages sent by the device and messages the device receives as a result of it being subscribed to some other device's broadcasts.
    * `received` messages received by the device and messages the device receives as a result of it being subscribed to some other device's received messages.
    * `sent` messages sent by the device and messages the device receives as a result of it being subscribed to some other device's sent messages.

##### Example

To subscribe to everything allowed for a device:

```javascript
meshblu.subscribe({uuid: '5c7392dc-a4ba-4b5a-8c84-5934a3b3678b'});
```

To subscribe to only broadcasts:

```javascript
meshblu.subscribe({uuid: '5c7392dc-a4ba-4b5a-8c84-5934a3b3678b', type: ['broadcast']});
```

## meshblu.unregister(query, callback)

Remove a device from the Meshblu device registry. In order to unregister a target device, your connection must be authenticated as a device that is in the target device's `configure.update` whitelist. See the [Meshblu whitelist documentation](https://meshblu.readme.io/docs/whitelists-2-0) for more information.

##### Arguments

* `query` Query object, must contain only the `uuid` property.
  * `uuid` UUID of the device to unregister.
* `callback` Function that will be called with a `result`.
  * `result` Response from the unregister call. Will contain either a `uuid` or an `error`, but never both.
    * `uuid` Uuid of the device that was unregistered
    * `error` String explaining the what went wrong. Is only present if something went wrong.

##### Note

In Meshblu, it is not possible to distinguish between a device not existing and not having permission to view a device. In most of the Meshblu API calls, the error in both cases yields the protocol-specific equivalent of an `HTTP 404: Not Found`. The Socket.IO API, however, returns the error `Forbidden`. This is for backwards compatibility and will likely change with the next major version release of the Socket.IO API.

##### Example

When unregister is called for a device the authenticated device may modify:

```javascript
meshblu.unregister({uuid: 'f52d8b52-ef04-44d3-ae45-59dfec2f7663'}, function(result){
  console.log('unregister');
  console.log(JSON.stringify(result, null, 2));
  // unregister
  // {
  //   "uuid": "f52d8b52-ef04-44d3-ae45-59dfec2f7663"
  // }
});
```

When unregister is called for a non-existing device, or device the authenticated device may modify:

```javascript
meshblu.unregister({uuid: 'i-made-this-uuid-up'}, function(result){
  console.log('unregister');
  console.log(JSON.stringify(result, null, 2));
  // unregister
  // {
  //   "error": "Forbidden"
  // }
});
```

## meshblu.unsubscribe(params)

Remove a subscription to a device's messages. Unsubscribe tries to unsubscribe the connection from every message type. To limit what is unsubscribed, use the `types` attribute.

##### Arguments

* `params`
  * `uuid` UUID of the device to unsubscribe from.
  * `types` Array of strings of types to unsubscribe from. Valid types are:
    * `broadcast` broadcast messages sent by the device and messages the device receives as a result of it being subscribed to some other device's broadcasts.
    * `received` messages received by the device and messages the device receives as a result of it being subscribed to some other device's received messages.
    * `sent` messages sent by the device and messages the device receives as a result of it being subscribed to some other device's sent messages.

##### Example

To unsubscribe from everything allowed for a device:

```javascript
meshblu.subscribe({uuid: '5c7392dc-a4ba-4b5a-8c84-5934a3b3678b'});
```

To unsubscribe from only broadcasts:

```javascript
meshblu.subscribe({uuid: '5c7392dc-a4ba-4b5a-8c84-5934a3b3678b', type: ['broadcast']});
```

## meshblu.update(query/update, callback)

Update a device in the Meshblu device registry. In order to update a target device, your connection must be authenticated as a device that is in the target device's `configure.update` whitelist. See the [Meshblu whitelist documentation](https://meshblu.readme.io/docs/whitelists-2-0) for more information.

##### Arguments

* `query/update` Both the query and update object. Must contain at least a `uuid`. Other than the listed exceptions, all other parameters will overwrite the device in the registry.
  * `uuid` UUID of the device to update. If omitted, it defaults to the UUID of the authenticated connection.
* `callback` Function that will be called with a `result`.
  * `result` Object passed to the callback.
    * `uuid` The uuid of the device that was updated.
    * `status` Status code of the update operation. Will always be `200`, even if the update did not happen.

##### Example

Updating a device:

```javascript
meshblu.update({uuid: 'c30a7506-7a45-4fe1-ab51-c57afad7f41a', color: 'blue'}, function(result){
  console.log('update');
  console.log(JSON.stringify(result, null, 2));
  // update
  // {
  //   "uuid": "78159106-41ca-4022-95e8-2511695ce64c",
  //   "status": 200
  // }
});
```

When updating a non-existing devices, or a device the authenticated connection may not update:

```javascript
meshblu.update({uuid: 'i-made-this-uuid-up', color: 'blue'}, function(result){
  console.log('update');
  console.log(JSON.stringify(result, null, 2));
  // update
  // {
  //   "uuid": "i-made-this-uuid-up",
  //   "status": 200
  // }
});
```

## meshblu.whoami(callback)

Retrieve the device the connection is currently authenticated as from the Meshblu device registery.

##### Arguments

* `callback` Function that will be called with a `device`.
  * `device` Full device from the Meshblu device registry.

##### Example

Calling whoami:
When whoami is called:

```javascript
meshblu.whoami(function(device){
  console.log('whoami');
  console.log(JSON.stringify(device, null, 2));
  // whoami
  // {
  //   "meshblu": {
  //     "version": "2.0.0",
  //     "whitelists": {},
  //     "createdAt": "2016-05-19T23:28:08+00:00",
  //     "hash": "4ez1I/uziZVk7INf6n1un+op/oNsIDoFVs/MW/KGWMQ=",
  //     "updatedAt": "2016-05-20T16:07:57+00:00"
  //   },
  //   "uuid": "78159106-41ca-4022-95e8-2511695ce64c",
  //   "online": true
  // }
});
```
