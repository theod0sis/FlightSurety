import Config from './config.json';
import Web3 from 'web3';
import FlightSuretyApp from "../../build/contracts/FlightSuretyApp.json";

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.firstAirline = config.firstAirline;
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    payAirlineFee(callback) {
        let self = this;
        console.log("first airline ", self.firstAirline);
        self.flightSuretyApp.methods
            .payRegistrationFee(self.firstAirline)
            .call({from: self.firstAirline, value: 10000000000000000000}, callback);
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {

            this.owner = accts[0];
            let counter = 1;
            while (this.airlines.length < 13) {
                this.airlines.push(accts[counter++]);
            }
            while (this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isOperational()
            .call({from: self.owner}, callback);
    }

    fetchAirline(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .fetchAirline(self.firstAirline)
            .call({from: self.firstAirline}, callback);
    }


    fetchRegisteredAirlines(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .fetchRegisteredAirlines()
            .call({from: self.owner}, callback);
    }

    registeredAirlines(addressToRegisterWith, id, name, address, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .registerAirline(id, name, address)
            .call({from: self.firstAirline}, callback);
    }

    registerFlight( airline, flight, flightTime, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .registerFlight(airline, flight, flightTime)
            .call({from: airline}, callback);
    }

    buyInsurance( passenger,airline, flight, flightTime,amount, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .buy(passenger,airline, flight, flightTime,amount)
            .call({from: passenger, value:amount}, callback);
    }


    withdrawMoney( passenger,amount, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .payInsurance(passenger,amount)
            .call({from: passenger}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        }
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }
}