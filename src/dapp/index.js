import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async () => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error, result);
            display('Operational Status', 'Check if contract is operational', [{
                label: 'Operational Status',
                error: error,
                value: result
            }]);
        });

        contract.payAirlineFee((error, result) => {
            console.log("payAirlineFee result: {}", result);
            console.log("payAirlineFee error: {}", error);
        });

        contract.fetchAirline((error, result) => {
            console.log("fetchAirline result: {}", result);
            console.log("fetchAirline error: {}", error);
        });

        contract.fetchRegisteredAirlines((error, result) => {
            console.log("fetchRegisteredAirlines result: {}", result);
            showAvailableAirlines(result, contract.airlines);
            showAvailablePassengers(contract.passengers);
        });

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [{
                    label: 'Fetch Flight Status',
                    error: error,
                    value: result.flight + ' ' + result.timestamp
                }]);
            });
        })

        DOM.elid('registerAirline').addEventListener('click', () => {
            let airlineId = DOM.elid('airlineId').value;
            let airlineAddress = DOM.elid('availableAirlineAddress').value;
            let airlineName = DOM.elid('airlineName').value;
            let airlineToRegister = DOM.elid('airlineToRegister').value;
            console.log(airlineToRegister);
            // Write transaction
            contract.registeredAirlines(airlineToRegister, airlineId, airlineName, airlineAddress, (error, result) => {
                console.log("The result was{}", result);
                console.log("The error was{}", error)
                alert("Airline " + airlineName + " was registered but Fee is not payed.")
            });
        })

        DOM.elid('addFlight').addEventListener('click', () => {
            let flightId = DOM.elid('flightId').value;
            let flightAirline = DOM.elid('flightAirline').value;
            let flightTime = DOM.elid('flightTime').value;
            console.log(airlineToRegister);
            // Write transaction
            contract.registerFlight(flightAirline, flightId, flightTime, (error, result) => {
                console.log("The result was{}", result);
                console.log("The error was{}", error);
                alert("flight " + flightId + " added");
            });
        })

        DOM.elid('buy-Insurance').addEventListener('click', () => {
            let insuranceFlightId = DOM.elid('insuranceFlightId').value;
            let passengerAddress = DOM.elid('passengerAddress').value;
            let airlineOfFlight = DOM.elid('airlineOfFlight').value;
            let timeOfFlight = DOM.elid('timeOfFlight').value;
            let insuranceAmount = DOM.elid('insuranceAmount').value;
            console.log(airlineToRegister);
            // Write transaction
            contract.buyInsurance(passengerAddress, airlineOfFlight, insuranceFlightId, timeOfFlight, insuranceAmount, (error, result) => {
                console.log("The result was{}", result);
                console.log("The error was{}", error);
                alert("Your insurance was accepted for flight " + flightId + " and amount "+insuranceAmount+"wei");
            });
        })

    });


})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className: 'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);
}

function showAvailableAirlines(results, availablesAirlines) {
    let displayDiv = DOM.elid("airlineToRegister");
    let available = DOM.elid("availableAirlineAddress");
    let airlinesForFlight = DOM.elid("flightAirline");
    let airlineOfFlight = DOM.elid("airlineOfFlight");
    results.map((result) => {
        for (var i = 0; i < availablesAirlines.length; i++) {
            if (availablesAirlines[i] === result) {
                availablesAirlines.splice(i, 1);
                i--;
            }
        }
        displayDiv.append(new Option(result));
        airlinesForFlight.append(new Option(result));
        airlineOfFlight.append(new Option(result));
    })
    availablesAirlines.forEach(airline => {
        available.append(new Option(airline))
    })
}

function showAvailablePassengers(passengers) {
    let passengerAddress = DOM.elid("passengerAddress");
    passengers.map((result) => {
        passengerAddress.append(new Option(result));
    })
}


