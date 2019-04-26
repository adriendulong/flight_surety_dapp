const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');

module.exports = function(deployer) {

  let firstAirline = '0xeF03573F1E1ea59DFD36802018968ca063f1a9b0';
  deployer.deploy(FlightSuretyData)
  .then(() => {
    return deployer.deploy(FlightSuretyApp)
      .then(() => {
        let config = {
          localhost: {
            url: 'http://localhost:8545',
            dataAddress: FlightSuretyData.address,
            appAddress: FlightSuretyApp.address
          }
        }
        fs.writeFileSync(__dirname + '/../src/dapp/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
        fs.writeFileSync(__dirname + '/../src/server/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
      });
  });
}