# FlightSurety DAPP
This is the forth project for @Udemy Blockchain developer Nanodegree. The purpose of this project is to create a smart
contract, an Oracle and the dapp that demonstrates an Airline registration and insurance payout to passenger in case of
an airline delay. The project started with boilerplate [code](https://github.com/udacity/FlightSurety). 
Smart Contract code is separated into multiple contracts:
    
    1) FlightSuretyData.sol for data persistence
    2) FlightSuretyApp.sol for app logic and oracles code
    
DAPP client have the functionalities of:

    1) Create an Airline 
        Createria to create Airline:
            -First airline is registered when contract is deployed.
            -Only existing airline may register a new airline until there are at least four airlines registered
            -Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines
            -Airline can be registered, but does not participate in contract until it submits funding of 10 ether
    2) Create a flight
    3) Passenger can buy an insurance for the flight
    4) Trigger Smart Contract to send random flight status
 
A server app has been created for simulating oracle behavior. Upon start up, 20+ oracles are registered and their 
assigned indexes are persisted in memory. Upon Smart Contract request a flight status update by emmiting an event if the
oracle have the index of the flight that Smart Contract requested, it will send one of the following flight status at 
random:
    
    1)Unknown (0)
    2)On Time (10)
    3)Late Airline (20)
    4)Late Weather (30)
    5)Late Technical (40)
    6)Late Other (50)  

## Technology versions used:
    - Solidity version ^0.5.16
    - Truffle version v5.1.20
    - truffle-hdwallet-provider version ^1.0.0-web3one.5
    - npm version 6.4.1
    - ganache

## Run FlightSurety dapp local:

First deploy the smart contract to local Ganache blockchain:

`npm install`
`truffle compile`
`truffle migrate --network development --reset`

Deploy server app that simulates oracles:

`npm run server`

An image like below is the expected outcome:

![TESTS](img/oraclesCreation.PNG?raw=true)

At a separate terminal start the dapp:
`npm run dapp`

## Run test cases:

To run the unit test run the following command:
`truffle test`

You can run them and separate:
`truffle test ./test/flightSurety.js`
`truffle test ./test/oracles.js`

The expected outcome :
![TESTS](img/TestCases.PNG?raw=true)


To view dapp:

`http://localhost:8000`

![TESTS](img/siteps.png?raw=true)

When you send a request for oracle flight status update the response will be logged in the terminal where you runned 
the server and will be something like the following image:

![TESTS](img/oracleRequest.PNG?raw=true)

## Useful Resources 

* [How does Ethereum work anyway?](https://medium.com/@preethikasireddy/how-does-ethereum-work-anyway-22d1df506369)
* [BIP39 Mnemonic Generator](https://iancoleman.io/bip39/)
* [Truffle Framework](http://truffleframework.com/)
* [Ganache Local Blockchain](http://truffleframework.com/ganache/)
* [Remix Solidity IDE](https://remix.ethereum.org/)
* [Solidity Language Reference](http://solidity.readthedocs.io/en/v0.4.24/)
* [Ethereum Blockchain Explorer](https://etherscan.io/)
* [Web3Js Reference](https://github.com/ethereum/wiki/wiki/JavaScript-API)