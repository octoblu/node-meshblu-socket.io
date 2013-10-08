var io = require("socket.io-client");

exports.connect = function(connectionParams){
// module.exports = function connect(connectionParams) {

  var host = connectionParams.host
  var port = connectionParams.port
  var uuid = connectionParams.uuid
  var token = connectionParams.token

  // Websocket controls
  this.socket = io.connect(host, {
      port: port
  });

  this.socket.on('connect', function(){
    console.log('Requesting websocket connection to Skynet');

    socket.on('identify', function(data){
      console.log('Websocket connected to Skynet with socket id: ' + data.socketid);
      console.log("Sending device uuid: " + uuid);
      socket.emit('identity', {uuid: uuid, socketid: data.socketid, token: token});
    });

    socket.on('authentication', function(data){
      if (data.status == 201){
        console.log('Device authenticated with Skynet');
      } else { // 401
        console.log('Device not authenticated with Skynet');
      }
    });

    // test APIs
    this.socket.emit('status');
    // socket.on('status', function(data){
    //   console.log('status received');
    //   console.log(data);
    // });


    // socket.emit('update', {"uuid":"ad698900-2546-11e3-87fb-c560cb0ca47b", "token": "zh4p7as90pt1q0k98fzvwmc9rmjkyb9", "key":"777"});
    socket.on('update', function(data){
      console.log('update received');
      console.log(data);
    });


    socket.on('message', function(data){
      console.log(data);      
    });
    socket.on('disconnect', function(){
      console.log('disconnect');
    });

  });

};