const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');

module.exports = function(deployer) {

  let firstAirline = '0xFaD3efF0Ea3E64734A8B8335459d6FE9377134D0';
  deployer.deploy(FlightSuretyData, firstAirline)
  .then(() => {
    console.log(`ADDRESS: ${FlightSuretyData.address}`)
    return deployer.deploy(FlightSuretyApp, FlightSuretyData.address)
      .then(async () => {
        const flightSuretyData = await FlightSuretyData.deployed()
        await flightSuretyData.authorizeContract(FlightSuretyApp.address);
        let config = {
          localhost: {
            url: 'http://localhost:8545',
            dataAddress: FlightSuretyData.address,
            appAddress: FlightSuretyApp.address
          }
        }
        fs.writeFileSync(__dirname + '/../src/dapp/src/abi/app.json',JSON.stringify(FlightSuretyApp.abi, null, '\t'), 'utf-8');
        fs.writeFileSync(__dirname + '/../src/dapp/src/abi/data.json',JSON.stringify(FlightSuretyData.abi, null, '\t'), 'utf-8');
        fs.writeFileSync(__dirname + '/../src/dapp/src/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
        fs.writeFileSync(__dirname + '/../src/server/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
      });
  });
}