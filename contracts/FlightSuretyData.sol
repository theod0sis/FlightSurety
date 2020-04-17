pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;
    bool private operational = true;
    uint private airlinesRegistered;
    address[] private availableAirlines;
    mapping(address => bool) private authorizedContracts;
    mapping(address => Airline) airlines;
    mapping(address => bool) airlinesFeePayed;
    mapping(address => mapping(bytes32 => uint)) passengerFlightInsuranceMap;
    mapping(address => uint) passengerFunds;
    mapping(bytes32 => address[]) flightPassengersMap;

    struct Airline {
        string id;
        string name;
        bool isRegistered;
        address airlineAddress;
    }



    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor(address _airline) public {
        contractOwner = msg.sender;
        airlines[_airline] = Airline({id : "agna",
            name : "Aegean Airline",
            isRegistered : true,
            airlineAddress : _airline});
        airlinesFeePayed[_airline] = true;
        airlinesRegistered = 1;
        availableAirlines.push(_airline);
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _;
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
   * @dev Modifier that requires the Message Sender to be one of the authorized Contracts
   */
    modifier requireIsCallerAuthorized() {
        require(authorizedContracts[msg.sender], "Caller is not authorized");
        _;
    }

    /**
    *  @dev Modifier that requires only a registered airline with payed fee
    */
    modifier requiresRegisteredAndFeePayedAirline(address existingAirline) {
        require(airlines[existingAirline].isRegistered == true, "Caller is not registered Airline or fee is payed ");
        require(airlinesFeePayed[existingAirline] == true, "Caller is not registered Airline or fee is payed ");
        _;
    }

    /**
    *  @dev Modifier that requires a registered airline ( we dont care about fee)
    */
    modifier requiresAirlineRegistered(address airlineAddress) {
        require(airlines[airlineAddress].isRegistered, "Airline is not registered");
        _;
    }

    /**
    *  @dev Modifier that requires a not registered airline
    */
    modifier requiresAirlineNotRegistered(address airlineAddress) {
        require(!airlines[airlineAddress].isRegistered, "Airline is already registered");
        _;
    }
    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational() public view requireIsCallerAuthorized returns (bool) {
        return operational;
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus(bool mode) external requireIsCallerAuthorized {
        require(operational != mode);
        operational = mode;
    }

    /**
    *@dev authorize a contract. Only contract owner can call this function
    */
    function authorizeCaller(address contractAddress) external requireContractOwner {
        authorizedContracts[contractAddress] = true;
    }

    /**
    *@dev deauthorize a contract. Only contract owner can call this function
    */
    function deauthorizeCaller(address contractAddress) external requireContractOwner {
        delete authorizedContracts[contractAddress];
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *      Only an existingAirline registered airline can register other airlines
     */
    function registerAirline(address _existingAirline, string _id, string _name, address _airlineAddress, bool isRegistered,
        bool registrationFeePayed) external
    requireIsCallerAuthorized requiresRegisteredAndFeePayedAirline(_existingAirline) requiresAirlineNotRegistered(_airlineAddress) {

        airlines[_airlineAddress] = Airline({
            id : _id,
            name : _name,
            isRegistered : isRegistered,
            airlineAddress : _airlineAddress
            });
        availableAirlines.push(_airlineAddress);
        airlinesRegistered.add(1);
    }

    function updateAirlineFeePayed(address _airlineAddress, bool payed) requireIsCallerAuthorized requiresAirlineRegistered(_airlineAddress) external returns (bool){
        airlinesFeePayed[_airlineAddress] = payed;
        return true;
    }

    /**
    * @dev Retrieves airline
    */
    function fetchAirline(address airlineAddress) requireIsCallerAuthorized external view returns (string id, string name,
        bool isRegistered, bool registrationFeePayed){
        Airline storage al = airlines[airlineAddress];
        return (al.id, al.name, al.isRegistered, airlinesFeePayed[airlineAddress]);
    }

    function isAirline(address airlineAddress) requireIsCallerAuthorized external view returns (bool isActive){
        return airlinesFeePayed[airlineAddress];
    }

    /**
     * @dev Retrieves num of registered airlines
     */
    function fetchRegisteredAirlines() external requireIsCallerAuthorized view returns (uint numOfAirlines){
        return airlinesRegistered;
    }
    /**
   * @dev Retrieves num of registered airlines
   */
    function fetchAllAirlines() external requireIsCallerAuthorized view returns (address[]){
        return availableAirlines;
    }
    /**
     * @dev Buy insurance for a flight
     */
    function buy(address _passengerAddress, bytes32 _flightKey, uint _insuranceAmount) requireIsCallerAuthorized external payable {
        //passenger can buy only one time insurance for a flight
        require(passengerFlightInsuranceMap[_passengerAddress][_flightKey] == 0);
        passengerFlightInsuranceMap[_passengerAddress][_flightKey];
        flightPassengersMap[_flightKey].push(_passengerAddress);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(bytes32 _flightKey) external view requireIsCallerAuthorized {
        address[] storage addressWithInsurance = flightPassengersMap[_flightKey];
        uint arrayLength = addressWithInsurance.length;
        for (uint i = 0; i < arrayLength; i++) {
            uint amountToBeAdded = passengerFlightInsuranceMap[addressWithInsurance[i]][_flightKey].mul(15).div(10);
            passengerFunds[addressWithInsurance[i]].add(amountToBeAdded);
        }
    }


    /**
     *  @dev Transfers eligible payout funds to insured
     *
    */
    function pay(address _passengerAddress, uint _amount) external payable requireIsCallerAuthorized {
        require(passengerFunds[_passengerAddress] >= _amount, "Passenger dont have this amount of money");
        passengerFunds[_passengerAddress].sub(_amount);
        _passengerAddress.transfer(_amount);
    }

    /**
     *  @dev Fetch balance for user
     *
    */
    function fetchPassengerBalance(address _passengerAddress) external requireIsCallerAuthorized view returns (uint balance) {
        return passengerFunds[_passengerAddress];
    }

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    function fund() external payable {
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable {
        this.fund();
    }


}

