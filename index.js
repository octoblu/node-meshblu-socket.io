var Connection = require('./lib/Connection');

module.exports = {
  createConnection: function (opt){
    return new Connection(opt);
  }
}

