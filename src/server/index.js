//import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
//import Config from './config.json';
const { GraphQLServer } = require('graphql-yoga');
const Web3 = require('web3');
const fs = require('fs');

const Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'));
console.log(Config);
const FlightSuretyApp = JSON.parse(fs.readFileSync('../../build/contracts/FlightSuretyApp.json', 'utf8'));
console.log(FlightSuretyApp);

let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

// Listen to event OracleRequest
flightSuretyApp.events.OracleRequest({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log(event)
});

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
server.start(() => console.log('Server is running on localhost:4000'))
