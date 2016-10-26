var BufferedSocket, Connection, NodeRSA, ProxySocket, _, stableStringify, url,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

stableStringify = require('json-stable-stringify');

_ = require('lodash');

NodeRSA = require('node-rsa');

url = require('url');

BufferedSocket = require('./buffered-socket');

ProxySocket = require('./proxy-socket');

Connection = (function(superClass) {
  extend(Connection, superClass);

  function Connection(options, dependencies) {
    var bufferRate, domain, hostname, port, protocol, ref, ref1, resolveSrv, secure, service, socket, srvOptions;
    if (dependencies == null) {
      dependencies = {};
    }
    this._uuidOrObject = bind(this._uuidOrObject, this);
    this._resolveSrv = bind(this._resolveSrv, this);
    this._resolveUri = bind(this._resolveUri, this);
    this._onReady = bind(this._onReady, this);
    this._onRateLimited = bind(this._onRateLimited, this);
    this._onMessage = bind(this._onMessage, this);
    this._onIdentify = bind(this._onIdentify, this);
    this._onConfig = bind(this._onConfig, this);
    this._encrypt = bind(this._encrypt, this);
    this._decrypt = bind(this._decrypt, this);
    this._buildUrlSocket = bind(this._buildUrlSocket, this);
    this._buildSrvSocket = bind(this._buildSrvSocket, this);
    this._buildSocket = bind(this._buildSocket, this);
    this._assertNoUrl = bind(this._assertNoUrl, this);
    this._assertNoSrv = bind(this._assertNoSrv, this);
    this.whoami = bind(this.whoami, this);
    this.verify = bind(this.verify, this);
    this.update = bind(this.update, this);
    this.unsubscribe = bind(this.unsubscribe, this);
    this.unregister = bind(this.unregister, this);
    this.subscribe = bind(this.subscribe, this);
    this.sign = bind(this.sign, this);
    this.revokeToken = bind(this.revokeToken, this);
    this.resetToken = bind(this.resetToken, this);
    this.register = bind(this.register, this);
    this.message = bind(this.message, this);
    this.identify = bind(this.identify, this);
    this.generateKeyPair = bind(this.generateKeyPair, this);
    this.generateAndStoreToken = bind(this.generateAndStoreToken, this);
    this.encryptMessage = bind(this.encryptMessage, this);
    this.devices = bind(this.devices, this);
    this.device = bind(this.device, this);
    this.connect = bind(this.connect, this);
    this.close = bind(this.close, this);
    this._BufferedSocket = (ref = dependencies.BufferedSocket) != null ? ref : BufferedSocket;
    this._console = (ref1 = dependencies.console) != null ? ref1 : console;
    this._options = options;
    this._subscriptions = [];
    if (options.privateKey) {
      this._privateKey = new NodeRSA(options.privateKey);
    }
    socket = options.socket, protocol = options.protocol, hostname = options.hostname, port = options.port, service = options.service, domain = options.domain, secure = options.secure, resolveSrv = options.resolveSrv, bufferRate = options.bufferRate;
    srvOptions = {
      protocol: protocol,
      hostname: hostname,
      port: port,
      service: service,
      domain: domain,
      secure: secure,
      resolveSrv: resolveSrv,
      socketIoOptions: options.options
    };
    this._socket = this._buildSocket({
      socket: socket,
      srvOptions: srvOptions,
      bufferRate: bufferRate
    });
    this._socket.on('config', this._onConfig);
    this._socket.on('identify', this._onIdentify);
    this._socket.on('message', this._onMessage);
    this._socket.on('ready', this._onReady);
    this._socket.on('ratelimited', this._onRateLimited);
    Connection.__super__.constructor.apply(this, arguments);
  }

  Connection.prototype.close = function(callback) {
    if (callback == null) {
      callback = function() {};
    }
    return this._socket.close(callback);
  };

  Connection.prototype.connect = function(callback) {
    if (callback == null) {
      callback = function() {};
    }
    return this._socket.connect(callback);
  };

  Connection.prototype.device = function(query, callback) {
    return this._socket.send('device', query, callback);
  };

  Connection.prototype.devices = function(query, callback) {
    return this._socket.send('devices', query, callback);
  };

  Connection.prototype.encryptMessage = function(uuid, toEncrypt, message, callback) {
    if (_.isFunction(message)) {
      callback = message;
      message = void 0;
    }
    return this._socket.send('getPublicKey', uuid, (function(_this) {
      return function(error, publicKey) {
        var encryptedPayload;
        if (error != null) {
          return _this._console.error("can't find public key for device");
        }
        encryptedPayload = _this._encrypt({
          publicKey: publicKey,
          data: toEncrypt
        });
        return _this._socket.send('message', _.defaults({
          encryptedPayload: encryptedPayload
        }, message), callback);
      };
    })(this));
  };

  Connection.prototype.generateAndStoreToken = function(query, callback) {
    return this._socket.send('generateAndStoreToken', query, callback);
  };

  Connection.prototype.generateKeyPair = function(bits) {
    var key;
    key = new NodeRSA;
    key.generateKeyPair(bits);
    return {
      privateKey: key.exportKey('private'),
      publicKey: key.exportKey('public')
    };
  };

  Connection.prototype.identify = function() {
    var auto_set_online, ref, token, uuid;
    ref = this._options, uuid = ref.uuid, token = ref.token, auto_set_online = ref.auto_set_online;
    return this._socket.send('identity', {
      uuid: uuid,
      token: token,
      auto_set_online: auto_set_online
    });
  };

  Connection.prototype.message = function(message, callback) {
    return this._socket.send('message', message, callback);
  };

  Connection.prototype.register = function(query, callback) {
    return this._socket.send('register', query, callback);
  };

  Connection.prototype.resetToken = function(data, callback) {
    data = this._uuidOrObject(data);
    return this._socket.send('resetToken', data, callback);
  };

  Connection.prototype.revokeToken = function(auth, callback) {
    return this._socket.send('revokeToken', auth, callback);
  };

  Connection.prototype.sign = function(data) {
    return this._privateKey.sign(stableStringify(data), 'base64');
  };

  Connection.prototype.subscribe = function(data) {
    data = this._uuidOrObject(data);
    this.subscriptions = _.unionBy(this.subscriptions, [data], _.isEqual);
    return this._socket.send('subscribe', data);
  };

  Connection.prototype.unregister = function(query, callback) {
    return this._socket.send('unregister', query, callback);
  };

  Connection.prototype.unsubscribe = function(data) {
    data = this._uuidOrObject(data);
    this.subscriptions = _.reject(this.subscriptions, data);
    return this._socket.send('unsubscribe', data);
  };

  Connection.prototype.update = function(query, callback) {
    return this._socket.send('update', query, callback);
  };

  Connection.prototype.verify = function(data, signature) {
    return this._privateKey.verify(stableStringify(data), signature, 'utf8', 'base64');
  };

  Connection.prototype.whoami = function(callback) {
    return this._socket.send('whoami', {}, callback);
  };

  Connection.prototype._assertNoSrv = function(arg) {
    var domain, secure, service;
    service = arg.service, domain = arg.domain, secure = arg.secure;
    if (domain != null) {
      throw new Error('resolveSrv is set to false, but received domain');
    }
    if (service != null) {
      throw new Error('resolveSrv is set to false, but received service');
    }
    if (secure != null) {
      throw new Error('resolveSrv is set to false, but received secure');
    }
  };

  Connection.prototype._assertNoUrl = function(arg) {
    var hostname, port, protocol;
    protocol = arg.protocol, hostname = arg.hostname, port = arg.port;
    if (protocol != null) {
      throw new Error('resolveSrv is set to true, but received protocol');
    }
    if (hostname != null) {
      throw new Error('resolveSrv is set to true, but received hostname');
    }
    if (port != null) {
      throw new Error('resolveSrv is set to true, but received port');
    }
  };

  Connection.prototype._buildSocket = function(arg) {
    var bufferRate, socket, srvOptions;
    socket = arg.socket, srvOptions = arg.srvOptions, bufferRate = arg.bufferRate;
    if (socket != null) {
      return socket;
    }
    if (srvOptions.resolveSrv) {
      return this._buildSrvSocket({
        srvOptions: srvOptions,
        bufferRate: bufferRate
      });
    }
    return this._buildUrlSocket({
      srvOptions: srvOptions,
      bufferRate: bufferRate
    });
  };

  Connection.prototype._buildSrvSocket = function(arg) {
    var bufferRate, ref, ref1, ref2, srvOptions;
    bufferRate = arg.bufferRate, srvOptions = arg.srvOptions;
    this._assertNoUrl(_.pick(srvOptions, 'protocol', 'hostname', 'port'));
    return new this._BufferedSocket({
      bufferRate: bufferRate,
      srvOptions: {
        resolveSrv: true,
        service: (ref = srvOptions.service) != null ? ref : 'meshblu',
        domain: (ref1 = srvOptions.domain) != null ? ref1 : 'octoblu.com',
        secure: (ref2 = srvOptions.secure) != null ? ref2 : true,
        socketIoOptions: srvOptions.socketIoOptions
      }
    });
  };

  Connection.prototype._buildUrlSocket = function(arg) {
    var bufferRate, ref, ref1, srvOptions;
    bufferRate = arg.bufferRate, srvOptions = arg.srvOptions;
    this._assertNoSrv(_.pick(srvOptions, 'service', 'domain', 'secure'));
    return new this._BufferedSocket({
      bufferRate: bufferRate,
      srvOptions: {
        resolveSrv: false,
        protocol: (ref = srvOptions.protocol) != null ? ref : 'wss',
        hostname: (ref1 = srvOptions.hostname) != null ? ref1 : 'meshblu-socket-io.octoblu.com',
        port: (function() {
          var ref2;
          try {
            return parseInt((ref2 = srvOptions.port) != null ? ref2 : 443);
          } catch (_error) {}
        })(),
        socketIoOptions: srvOptions.socketIoOptions
      }
    });
  };

  Connection.prototype._decrypt = function(arg) {
    var data;
    data = arg.data;
    return JSON.parse(this._privateKey.decrypt(data));
  };

  Connection.prototype._encrypt = function(arg) {
    var data, publicKey;
    publicKey = arg.publicKey, data = arg.data;
    return new NodeRSA(publicKey).encrypt(stableStringify(data), 'base64');
  };

  Connection.prototype._onConfig = function(config) {
    return this.emit('config', config);
  };

  Connection.prototype._onIdentify = function() {
    return this.identify();
  };

  Connection.prototype._onMessage = function(message) {
    if (message.encryptedPayload != null) {
      message.encryptedPayload = this._decrypt({
        data: message.encryptedPayload
      });
    }
    return this.emit('message', message);
  };

  Connection.prototype._onRateLimited = function(data) {
    return this.emit('ratelimited', data);
  };

  Connection.prototype._onReady = function() {
    return _.each(this.subscriptions, this.subscribe);
  };

  Connection.prototype._resolveUri = function(callback) {
    var hostname, port, protocol, ref;
    if (this._options.resolveSrv) {
      return this._resolveSrv(callback);
    }
    ref = this._options, protocol = ref.protocol, hostname = ref.hostname, port = ref.port;
    return callback(null, url.format({
      protocol: protocol,
      hostname: hostname,
      port: port,
      slashes: true
    }));
  };

  Connection.prototype._resolveSrv = function(callback) {
    var domain, ref, service;
    ref = this._options, service = ref.service, domain = ref.domain;
    return this._dns.resolveSrv("_" + service + "._socket-io-wss." + domain, (function(_this) {
      return function(error, addresses) {
        var address;
        if (error != null) {
          return callback(error);
        }
        address = _.first(addresses);
        return callback(null, url.format({
          protocol: 'wss',
          hostname: address.name,
          port: address.port,
          slashes: true
        }));
      };
    })(this));
  };

  Connection.prototype._uuidOrObject = function(data) {
    if (_.isString(data)) {
      return {
        uuid: data
      };
    }
    return data;
  };

  return Connection;

})(ProxySocket);

module.exports = Connection;

// ---
// generated by coffee-script 1.9.2
