import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';
const regeneratorRuntime = require("regenerator-runtime");



let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
let flightSuretyData = new web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);

let oracles = {};
let amount;

web3.eth.getAccounts().then(accounts => {
    authorizeApp(accounts[0]).then(() => {
        for (let a = 1; a <= 20; a++) {
            flightSuretyApp.methods.registerOracle()
                .send({from: accounts[a], value: amount, gas: 2000000})
                .then(() => {
                    flightSuretyApp.methods.getMyIndexes().call({from: accounts[a]})
                        .then(indexes => {
                            oracles[accounts[a]] = indexes;
                            console.log("oracle created with index"+indexes)
                        }).catch(() => (console.log("Error on getting indexed")));
                }).catch(error => (console.log("Error on Register Oracle "+error)));
        }
    }).catch(e => console.log("error on Auth"+e));
}).catch(err =>console.log("error:"+err));

async function authorizeApp(account) {

    await flightSuretyData.methods.authorizeCaller(config.appAddress)
        .send({from: account})
        .then(() => console.log("App authorized"))
        .catch(() => (console.log("Error on App authorization")));

    await flightSuretyApp.methods.REGISTRATION_FEE().call()
        .then(resolve => {
            amount = resolve;
            console.log(amount)
        }).catch(() => (console.log("Error on App authorization")));
}

flightSuretyApp.events.FlightStatusInfo({}, function (error, event) {
        if (error) {
            console.log(error);
        } else {
            console.log("Flight status info event:  " + JSON.stringify(event));
        }
    }
);

flightSuretyApp.events.OracleReport({}, function (error, event) {
        if (error) {
            console.log(error);
        } else {
            console.log("Oracle report :  " + JSON.stringify(event));
        }
    }
);


flightSuretyApp.events.OracleRequest({},
    function (error, event) {
        if (error) {
            console.log(error)
            return;
        }
        console.log(event);
        for (const [key, value] of Object.entries(oracles)) {
            console.log(key, value);
            if (value.includes(event.returnValues.index)) {
                flightSuretyApp.methods.submitOracleResponse(event.returnValues.index, event.returnValues.airline,
                    event.returnValues.flight, event.returnValues.timestamp, getRndStatus())
                    .send({from: key})
                    .then(() => {
                        console.log("Oracle send the request");
                    }).catch(e => {
                    console.log("Error while sending Oracle request to Contract {}", e)
                });
            }
        }
    });


function getRndStatus() {
    return Math.floor(Math.random() * 6) * 10;
}

const app = express();
app.get('/api', (req, res) => {
    res.send({
        message: 'An API for use with your Dapp!'
    })
})

export default app;


