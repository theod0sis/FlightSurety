pragma solidity ^0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256;

    FlightSuretyData data;
    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;
    mapping(address => uint) private votesForAirline;
    address private contractOwner;
    uint public AIRLINE_REGISTRATION_FEE = 10 ether;
    uint8 private nonce = 0;
    uint256 public constant REGISTRATION_FEE = 1 ether;
    uint256 private constant MIN_RESPONSES = 3;

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }

    mapping(bytes32 => Flight) private flights;

    event AirlineRegistered(string id, string name, address airlineAddress, bool open);


    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() {
        require(data.isOperational(), "Contract is currently not operational");
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
    * @dev Modifier to check if the timestamp is valid. Not very secure because miners can change the time of blockchain
    */
    modifier requireValidTimestamp(uint _timestamp) {
        require(_timestamp >= now,"Not valid timestamp");
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor(address dataContractAddress) public {
        contractOwner = msg.sender;
        data = FlightSuretyData(dataContractAddress);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view returns (bool){
        return data.isOperational();
    }

    function setOperatingStatus(bool mode) public requireContractOwner {
        return data.setOperatingStatus(mode);
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/


    /**
     * @dev Add an airline to the registration queue
     *
     */
    function registerAirline(string _id, string _name, address _airlineAddress) public requireIsOperational returns (bool success, uint256 votes){
        require(_airlineAddress != address(0), "'airline' must be a valid address.");
        uint airlinesRegistered = data.fetchRegisteredAirlines();
        if (airlinesRegistered < 4) {
            data.registerAirline(msg.sender, _id, _name, _airlineAddress, true, false);
            emit AirlineRegistered(_id, _name, _airlineAddress, false);
            return (true, 0);
        } else {
            if (votesForAirline[_airlineAddress] < airlinesRegistered.div(2)) {
                votesForAirline[_airlineAddress].add(1);
                emit AirlineRegistered(_id, _name, _airlineAddress, true);
                return (false, votesForAirline[_airlineAddress]);
            } else {
                data.registerAirline(msg.sender, _id, _name, _airlineAddress, true, false);
                votesForAirline[_airlineAddress].add(1);
                emit AirlineRegistered(_id, _name, _airlineAddress, false);
                return (true, votesForAirline[_airlineAddress]);
            }
        }
    }

    function fetchRegisteredAirlines() requireIsOperational external view returns (address[]){
        return data.fetchAllAirlines();
    }

    function payRegistrationFee(address airline) requireIsOperational public payable returns (bool success) {
        require(msg.value >= AIRLINE_REGISTRATION_FEE, "Minimum fee to activate airline is not payed");
        require(airline == msg.sender, "airline have to be the same with sender");
        data.fund.value(msg.value)();
        return data.updateAirlineFeePayed(airline, true);
    }

    /**
     * @dev Register a future flight for insuring.
     *
     */
    function registerFlight(address _airline, string _flight, uint _timestamp) external requireIsOperational requireValidTimestamp(_timestamp) {
        (string memory _id, string memory _name, bool _isRegistered, bool _registrationFeePayed) = data.fetchAirline(_airline);
        require(_registrationFeePayed);
        bytes32 _key = getFlightKey(_airline, _flight, _timestamp);
        require(!flights[_key].isRegistered);
        flights[_key] = Flight({
                    isRegistered : true,
                    statusCode : STATUS_CODE_UNKNOWN,
                    updatedTimestamp : _timestamp,
                    airline : _airline });
    }

    /**
     * @dev Called after oracle has updated flight status
     *
     */
    function processFlightStatus(address _airline, string memory _flight, uint256 _timestamp, uint8 _statusCode)
                                                    internal requireIsOperational requireValidTimestamp(_timestamp) {

        require(_statusCode == STATUS_CODE_LATE_AIRLINE);
        data.creditInsurees(getFlightKey(_airline, _flight, _timestamp));
    }

    /**
    * @dev fetch data for a airline
    */
    function fetchAirline(address _airline)  external requireIsOperational view returns( string id, string name,
                                                    bool isRegistered, bool registrationFeePayed) {
        return  data.fetchAirline(_airline);
    }

    /**
    * @dev Generate a request for oracles to fetch flight information
    */
    function fetchFlightStatus(address airline, string flight, uint256 timestamp) external requireIsOperational {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
            requester : msg.sender,
            isOpen : true
            });

        emit OracleRequest(index, airline, flight, timestamp);
    }


    function buy(address _passengerAddress, address airline, string flight, uint256 timestamp, uint _insuranceAmount) requireIsOperational external payable{
        require(_insuranceAmount == msg.value,"not same money was sent");
        bytes32 key = getFlightKey(airline, flight,timestamp);
        data.buy.value(msg.value)(_passengerAddress,key,_insuranceAmount);
    }

    function pay(address _passengerAddress, uint _amount) external payable requireIsOperational {
        data.pay(_passengerAddress, _amount);
    }


        // region ORACLE MANAGEMENT

    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
        // This lets us group responses and identify
        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle() external payable {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
            isRegistered : true,
            indexes : indexes
            });
    }

    function getMyIndexes() view external returns (uint8[3]){
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");
        return oracles[msg.sender].indexes;
    }


    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(uint8 index, address airline, string flight, uint256 timestamp, uint8 statusCode) external {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey(address airline, string flight, uint256 timestamp) pure internal returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account) internal returns (uint8[3]) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while (indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address account) internal returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;
            // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

    // endregion
}

contract FlightSuretyData {
    // functions util
    function isOperational() public view returns (bool);

    function setOperatingStatus(bool mode) external;

    function authorizeCaller(address contractAddress) external;

    function deauthorizeCaller(address contractAddress) external;

    //main functions
    function updateAirlineFeePayed(address _airlineAddress, bool payed) external returns (bool);

    function registerAirline(address _existingAirline, string _id, string _name, address _airlineAddress, bool isRegistered, bool registrationFeePayed) external;

    function fetchAirline(address airlineAddress) external view returns (string id, string name, bool isRegistered, bool registrationFeePayed);

    function fetchRegisteredAirlines() external view returns (uint numOfAirlines);

    function fetchAllAirlines() external view returns (address[]);

    function pay(address _passengerAddress, uint _amount) external payable;

    function creditInsurees(bytes32 _flightKey) external;

    function buy(address _passengerAddress, bytes32 _flightKey, uint _insuranceAmount) external payable;

    function fetchPassengerBalance(address _passengerAddress) external returns (uint balance);

    function fund() external payable;
}
