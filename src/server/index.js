//import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
//import Config from './config.json';
const { GraphQLServer } = require('graphql-yoga');
const ethers = require('ethers');
const fs = require('fs');

const Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'));
const FlightSuretyApp = JSON.parse(fs.readFileSync('../../build/contracts/FlightSuretyApp.json', 'utf8'));

const STATUS_CODE_UNKNOWN = 0;
const STATUS_CODE_ON_TIME = 10;
const STATUS_CODE_LATE_AIRLINE = 20;
const STATUS_CODE_LATE_WEATHER = 30;
const STATUS_CODE_LATE_TECHNICAL = 40;
const STATUS_CODE_LATE_OTHER = 50;

const STATUS = [
  STATUS_CODE_UNKNOWN,
  STATUS_CODE_ON_TIME,
  STATUS_CODE_LATE_AIRLINE,
  STATUS_CODE_LATE_WEATHER,
  STATUS_CODE_LATE_TECHNICAL,
  STATUS_CODE_LATE_OTHER
];

let config = Config['localhost'];
let provider = new ethers.providers.JsonRpcProvider()
let flightSuretyApp = new ethers.Contract(config.appAddress, FlightSuretyApp.abi, provider);

let oraclesIndexes = {};




// Listen to event OracleRequest
flightSuretyApp.on("OracleRequest", async (index, airline, flight, timestamp, event) => {
  console.log("OracleRequest", index, airline, flight, timestamp);
  console.log("Block", event.blockNumber);
  await oracleRepondDelayed(index, airline, flight, timestamp);
})

flightSuretyApp.on("FlightStatusInfo", (airline, flight, timestamp, status, event) => {
  console.log("FlightStatusInfo", airline, flight, timestamp);
  console.log("STATUS", status);
  console.log("Block", event.blockNumber);
})

const typeDefs = `
  type Query {
    hello(name: String): String!
  }
`

const resolvers = {
  Query: {
    hello: (_, { name }) => `Hello ${name || 'World'}`,
  },
}


const server = new GraphQLServer({ typeDefs, resolvers })
server.start(async () => {
  console.log('Server is running on localhost:4000');
  let accounts = await provider.listAccounts();
  let oracles = accounts.slice(0,30);
  for(oracle of oracles) {
    await registerOracle(oracle);
  }
  console.log(oraclesIndexes);
});


async function registerOracle(account) {
  let contractWithSigner = flightSuretyApp.connect(provider.getSigner(account));

  let tx = await contractWithSigner.registerOracle({value: ethers.utils.parseEther('1.0')});
  console.log(tx.hash);
  await tx.wait();
  let newValue = await contractWithSigner.getMyIndexes();
  console.log(newValue);
  oraclesIndexes[account] = newValue;
}

async function oracleRepond(index, airline, flight, timestamp) {
  for(let key in oraclesIndexes) {
    if(oraclesIndexes[key].includes(index)) {
      console.log("Oracles need to answer", key);
      const randomStatus = Math.floor((Math.random() * STATUS.length));
      console.log("SEND STATUS", STATUS[randomStatus]);
      let contractWithSigner = flightSuretyApp.connect(provider.getSigner(key));
      let tx = await contractWithSigner.submitOracleResponse(index, airline, flight, timestamp, STATUS[randomStatus]);
      console.log(tx.hash);
    }
  }
}

async function oracleRepondDelayed(index, airline, flight, timestamp) {
  for(let key in oraclesIndexes) {
    if(oraclesIndexes[key].includes(index)) {
      console.log("Oracles need to answer", key);
      let contractWithSigner = flightSuretyApp.connect(provider.getSigner(key));
      let tx = await contractWithSigner.submitOracleResponse(index, airline, flight, timestamp, STATUS_CODE_LATE_AIRLINE);
      console.log(tx.hash);
    }
  }
}