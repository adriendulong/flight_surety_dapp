# Flight Surety Project

This project is developed in the context of the [Udacity Blockchain Nanodegree](https://eu.udacity.com/course/blockchain-developer-nanodegree--nd1309)

The goal of this project is to build a dApp (Decentralized application) using smart contracts and web3 technology.
This project tackles these specific points:
* Multi-party consensus
* Oracles
* Receive, transfer and send funds
* Smart Contract upgradability
* Fail fast contracts

In this app a passenger can:
* Subscribe insurance to a flight
* If the flight is delayed due to the company the passenger will get 1.5x the amount of ether he put in the insurance
* The passenger can withdraw the ether from the smart contract

For airlines, the smart contract allows to:
* Submit a new airline to the smart contract
* Vote for a new airline to reach a 50% consensus
* Add a flight

We have a server that simulates the behavior of oracles that:
* Listen to a specific event that the smart contract will trigger when info about a flight is needed
* Generate the info about flights and send them to the smart contract

##  How to use and deploys the app
1) **Compile the smart contracts**: from the root of the project make a `truffle compile` (you must have truffle installed globally)
2) **Run the local chain** doing `npm run chain` or `yarn run chain`
3) **Deploy the smart contract**  doing `truffle migrate`
4) **Launch the server** doing `cd src/server && npm start`
5) **Launch the dapp** doing (from the project root) `cd src/dapp && npm start`

## How to test the smart contracts
1) **Run the local chain** doing `npm run chain` or `yarn run chain`
2) From the project root make a `truffle test`

## Use the dapp

*Get insurance for a flight*

The first block allows you to choose a flight, enter an amount of ETH and validate to get insurance for a flight.
You should not be able to put more than 1 ETH by flight.

*Check Insurance amount*

The second block allows you to check the amount you put in insurance for a specific flight

*Fetch flight status*

Choose a flight and click on the button. It will trigger the event that the Oracles listened. 
Oracles will answer with the flight status.
For testing purpose, the Oracles will give back a status that triggers the insurance.
At the bottom of the screen you should see your balance being updated (you received 1.5x the amount you put in the assurance, however your funds are still on the smart contract, you must withdraw them to
get them in your wallet).

*Your balance*

Here you have the amount of ETH you own and that the smart contract still holds. 
You can withdraw them whenever you want.
