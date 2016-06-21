require('coffee-script/register');
var Connection = require('./src/Connection');

module.exports = {
  createConnection: function (opt){
    var connection = new Connection(opt);
    connection.connect();
    return connection;
  }
};
