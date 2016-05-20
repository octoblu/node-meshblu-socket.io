# node-meshblu-socket.io

[![Build Status](https://travis-ci.org/octoblu/meshblu-npm.svg?branch=master)](https://travis-ci.org/octoblu/meshblu-npm)
[![Code Climate](https://codeclimate.com/github/octoblu/meshblu-npm/badges/gpa.svg)](https://codeclimate.com/github/octoblu/meshblu-npm)
[![Test Coverage](https://codeclimate.com/github/octoblu/meshblu-npm/badges/coverage.svg)](https://codeclimate.com/github/octoblu/meshblu-npm)

A client side library for using the [Meshblu Socket.IO API](https://meshblu-socketio.readme.io/) in [Node.js](https://nodejs.org)

# Table of Contents

* [Getting Started](#getting-started)
  * [Install](#install)
  * [Quick Start](#quick-start)
* [Events](#events)
  * [Event: 'ready'](#event-ready)
* [Methods](#methods)
  * [createConnection](#createConnection)

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

## Event: 'ready'

* `device` The device the connection is authenticated as.

The device will always include the `uuid` and plain-text `token`. The `token` is passed through by the API so that it can be returned here, it is never stored as plain text by Meshblu.

#### Example

```javascript
conn.on('ready', function(device){
  console.log('ready');
  console.log(JSON.stringify(device, null, 2));
  // ready
  // {
  //   "api": "connect",
  //   "status": 201,
  //   "uuid": "78159106-41ca-4022-95e8-2511695ce64c",
  //   "token": "d5265dbc4576a88f8654a8fc2c4d46a6d7b85574"
  // }
});
```

# Methods

## createConnection(options)

Establishes a socket.io connection to meshblu and returns the connection object.

#### Arguments

* `options` - connection options with the following keys:
  * `server` - The hostname of the Meshblu server to connect to. (Default: `meshblu-socket-io.octoblu.com`)
  * `port` - The port of the Meshblu server to connect to. (Default: `443`)
  * `uuid` - UUID of the device to connect with.
  * `token` - Token of the device to connect with.

#### Note

If the `uuid` and `token` options are omitted, Meshblu will create a new device when the connection is established and emit a `ready` event with the device's credentials. This will be the only time that device's `token` is available as plain text. This auto device creation feature exists for backwards compatibility, it's use in new projects is strongly discouraged.

#### Example

```javascript
var conn = meshblu.createConnection({
  server: 'meshblu-socket-io.octoblu.com'
  port: 443
  uuid: '78159106-41ca-4022-95e8-2511695ce64c',
  token: 'd5265dbc4576a88f8654a8fc2c4d46a6d7b85574'
});
```
