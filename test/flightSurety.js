// Import all required modules from openzeppelin-test-helpers
const { BN, constants, expectEvent, shouldFail } = require('openzeppelin-test-helpers');

const { expect } = require('chai');

const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");

contract('Flight Surety Tests', async (accounts) => {

  const firstAirline = accounts[1];

  before('setup contract', async () => {
    const flightSuretyData = await FlightSuretyData.deployed();
    await flightSuretyData.authorizeContract(FlightSuretyApp.address);
    const flightSuretyApp = await FlightSuretyApp.deployed();

    // fund firstAirline
    const funds = web3.utils.toWei("10");
    await flightSuretyApp.submitFunds({from: firstAirline, value: funds});
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  // it(`(multiparty) has correct initial isOperational() value`, async function () {

  //   // Get operating status
  //   const flightSuretyData = await FlightSuretyData.deplyed();
  //   let status = await flightSuretyData.isOperational();
  //   assert.equal(status, true, "Incorrect initial operating status value");

  // });

  it(`Add 3 more airlines and no more`, async function () {

    // Get an instance of the deployed contract
    const flightSuretyApp = await FlightSuretyApp.deployed();

    // Add an airline
    const airlineOne = await flightSuretyApp.addAirline(accounts[2], {from: firstAirline});
    // Check that an event is emitted by the FlightSuretyData contract
    expectEvent.inTransaction(airlineOne.tx, FlightSuretyData, 'AirlineRegistered', { airline: accounts[2], countAirlines: new BN(2) });

    // Repeat the same for two more airlines
    const airlineTwo = await flightSuretyApp.addAirline(accounts[3], {from: firstAirline});
    expectEvent.inTransaction(airlineTwo.tx, FlightSuretyData, 'AirlineRegistered', { airline: accounts[3], countAirlines: new BN(3) });
    const airlineThree = await flightSuretyApp.addAirline(accounts[4], {from: firstAirline});
    expectEvent.inTransaction(airlineThree.tx, FlightSuretyData, 'AirlineRegistered', { airline: accounts[4], countAirlines: new BN(4) });

    // Check that a fifth one will fail
    shouldFail.reverting.withMessage(flightSuretyApp.addAirline(accounts[5], { from: firstAirline}), "FlightSuretyApp::addAirline - Already 4 airlines have been added, you must pas by the queue process");

  });

  it("Can't add an airline if this is not an airline", async function() {
     // Get an instance of the deployed contract
     const flightSuretyApp = await FlightSuretyApp.deployed();

     // Can't add an airline if the caller is not an airline
     await shouldFail.reverting.withMessage(flightSuretyApp.addAirline(accounts[5], { from: accounts[10] }), "FlightSuretyApp::isParticipatingAirline - This airline is not yet able to participate");
  })

  it("Consensus for a new airline", async function() {
    // Get an instance of the deployed contract
    const flightSuretyApp = await FlightSuretyApp.deployed();
    const flightSuretyData = await FlightSuretyData.deployed();

    // Fund airline 2, 3 and 4
    const funds = web3.utils.toWei("10");
    await flightSuretyApp.submitFunds({from: accounts[2], value: funds});
    await flightSuretyApp.submitFunds({from: accounts[3], value: funds});
    await flightSuretyApp.submitFunds({from: accounts[4], value: funds});

    const airlineQueued = accounts[5];

    // Queue a new airline
    const response = await flightSuretyApp.queueAirline({from: airlineQueued});
    expectEvent.inLogs(response.logs, 'AirlineQueued', { airline: airlineQueued});

    // Only airlines should be able  
    await shouldFail.reverting.withMessage(flightSuretyApp.voteAirline(airlineQueued, {from: accounts[10]}), "FlightSuretyApp::isParticipatingAirline - This airline is not yet able to participate");
    // Vote for the airline
    await flightSuretyApp.voteAirline(airlineQueued, {from: accounts[1]});
    await flightSuretyApp.voteAirline(airlineQueued, {from: accounts[2]});

    // The third vote should trigger an event letting us know that the airlineQueued has been registered 
    // since we reached more than 50% of the votes
    const votes = await flightSuretyApp.voteAirline(airlineQueued, {from: accounts[3]});
    expectEvent.inTransaction(votes.tx, FlightSuretyData, 'AirlineRegistered', { airline: airlineQueued });
    
    
 })

 it("Ariline can't participate if did not fund the contract", async function() {
  // Get an instance of the deployed contract
  const flightSuretyApp = await FlightSuretyApp.deployed();

  const airlineQueued = accounts[5];

  // Check that the ariline can't participate
  let timestamp = Math.floor(Date.now() / 1000);
  await shouldFail.reverting.withMessage(flightSuretyApp.registerFlight("ND007", timestamp, {from: airlineQueued}), "FlightSuretyData::needAirlineParticipating: This airline is not yet able to participate");
  
  
})

 it("Arline can fund the contract to participate", async function() {
  // Get an instance of the deployed contract
  const flightSuretyApp = await FlightSuretyApp.deployed();

  const airlineQueued = accounts[5];
  const funds = web3.utils.toWei("10");

  // Participate
  const response = await flightSuretyApp.submitFunds({from: airlineQueued, value: funds});
  // Check that we receive the events that notify us that the airline has been addded to the list of airline that can participate
  expectEvent.inTransaction(response.tx, FlightSuretyData, 'AirlineParticipating', { airline: airlineQueued });
  
  // Should be able to register a flight
  const flightName = "ND007";
  let timestamp = Math.floor(Date.now() / 1000);
  const flight = await flightSuretyApp.registerFlight(flightName, timestamp, {from: airlineQueued});
  expectEvent.inTransaction(flight.tx, FlightSuretyData, 'FlightAdded', { airline: airlineQueued, flight: flightName });

  
})

it("Flight creation works", async function() {
 // Get an instance of the deployed contract
 const flightSuretyApp = await FlightSuretyApp.deployed();

 const flightsBeginning = await flightSuretyApp.getFlightKeys();

 let timestamp = Math.floor(Date.now() / 1000);
 const flightName = "ND008";
 const flightAdded = await flightSuretyApp.registerFlight(flightName, timestamp, {from: accounts[5]});
 expectEvent.inTransaction(flightAdded.tx, FlightSuretyData, 'FlightAdded', { airline: accounts[5], flight: flightName });

 const flightsAfter = await flightSuretyApp.getFlightKeys();
 assert.equal(flightsAfter.length, (flightsBeginning.length + 1), "Flight not added");
 
})

//   it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

//       // Ensure that access is denied for non-Contract Owner account
//       let accessDenied = false;
//       try 
//       {
//           await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
//       }
//       catch(e) {
//           accessDenied = true;
//       }
//       assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
//   });

//   it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

//       // Ensure that access is allowed for Contract Owner account
//       let accessDenied = false;
//       try 
//       {
//           await config.flightSuretyData.setOperatingStatus(false);
//       }
//       catch(e) {
//           accessDenied = true;
//       }
//       assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
//   });

//   it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

//       await config.flightSuretyData.setOperatingStatus(false);

//       let reverted = false;
//       try 
//       {
//           await config.flightSurety.setTestingMode(true);
//       }
//       catch(e) {
//           reverted = true;
//       }
//       assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

//       // Set it back for other tests to work
//       await config.flightSuretyData.setOperatingStatus(true);

//   });

//   it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
//     // ARRANGE
//     let newAirline = accounts[2];

//     // ACT
//     try {
//         await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
//     }
//     catch(e) {

//     }
//     let result = await config.flightSuretyData.isAirline.call(newAirline); 

//     // ASSERT
//     assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

//   });
 

});
