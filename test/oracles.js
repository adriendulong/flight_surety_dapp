// const FlightSuretyApp = artifacts.require("FlightSuretyApp");
// const FlightSuretyData = artifacts.require("FlightSuretyData");

// const { BN, constants, expectEvent, shouldFail } = require('openzeppelin-test-helpers');
// const { expect } = require('chai');

// contract('Oracles', async (accounts) => {

//   const TEST_ORACLES_COUNT = 20;
//   // Watch contract events
//   const STATUS_CODE_UNKNOWN = 0;
//   const STATUS_CODE_ON_TIME = 10;
//   const STATUS_CODE_LATE_AIRLINE = 20;
//   const STATUS_CODE_LATE_WEATHER = 30;
//   const STATUS_CODE_LATE_TECHNICAL = 40;
//   const STATUS_CODE_LATE_OTHER = 50;

//   const firstAirline = accounts[1];
//   let flight = 'ND1309'; // Course number
//   let timestamp = Math.floor(Date.now() / 1000);

//   before('setup contract', async () => {
//     const flightSuretyData = await FlightSuretyData.deployed();
//     await flightSuretyData.authorizeContract(FlightSuretyApp.address);
//     const flightSuretyApp = await FlightSuretyApp.deployed();

//     // fund firstAirline
//     const funds = web3.utils.toWei("10");
//     await flightSuretyApp.submitFunds({from: firstAirline, value: funds});
//   });

//   it('can register oracles', async () => {
    
//     // ARRANGE
//     const flightSuretyApp = await FlightSuretyApp.deployed();
//     let fee = await flightSuretyApp.REGISTRATION_FEE.call();

//     // ACT
//     for(let a=1; a<TEST_ORACLES_COUNT; a++) {      
//       await flightSuretyApp.registerOracle({ from: accounts[a], value: fee });
//       let result = await flightSuretyApp.getMyIndexes.call({from: accounts[a]});
//       console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
//     }
//   });

//   it('can request flight status', async () => {
    
//     const flightSuretyApp = await FlightSuretyApp.deployed();

//     // // Submit a request for oracles to get status information for a flight
//      await flightSuretyApp.fetchFlightStatus(firstAirline, flight, timestamp);
//     // // ACT

//     // Since the Index assigned to each test account is opaque by design
//     // loop through all the accounts and for each account, all its Indexes (indices?)
//     // and submit a response. The contract will reject a submission if it was
//     // not requested so while sub-optimal, it's a good test of that feature
//     for(let a=1; a<TEST_ORACLES_COUNT; a++) {

//       // Get oracle information
//       let oracleIndexes = await flightSuretyApp.getMyIndexes.call({ from: accounts[a]});
//       for(let idx=0;idx<3;idx++) {

//         let response = null;
//         try {
//           // Submit a response...it will only be accepted if there is an Index match
//           response = await flightSuretyApp.submitOracleResponse(oracleIndexes[idx], firstAirline, flight, timestamp, STATUS_CODE_LATE_AIRLINE, { from: accounts[a] });

//         }
//         catch(e) {
//           // Enable this when debugging
//            console.log('\nError', idx, oracleIndexes[idx].toNumber(), flight, timestamp);
//         }

//       }
//     }

//     let status = await flightSuretyApp.getFlightStatus(firstAirline, flight, timestamp);
//     expect(status).to.be.bignumber.equal(new BN(STATUS_CODE_LATE_AIRLINE));
//   });


 
// });
