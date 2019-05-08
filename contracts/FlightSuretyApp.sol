pragma solidity ^0.5.2;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./interfaces/IFlightSuretyData.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
	using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

	/********************************************************************************************/
	/*                                       DATA VARIABLES                                     */
	/********************************************************************************************/

	bool private operational = true;
	IFlightSuretyData public flightSuretyData;

	// Flight status codees
	uint8 private constant STATUS_CODE_UNKNOWN = 0;
	uint8 private constant STATUS_CODE_ON_TIME = 10;
	uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
	uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
	uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
	uint8 private constant STATUS_CODE_LATE_OTHER = 50;

	// Amount minimum to participate
	uint private constant MINIMUM_AIRLINE_FUNDING = 10 ether;

	uint private constant MAXIMUM_INSURANCE = 1 ether;

	address private contractOwner;          // Account used to deploy contract

	struct Flight {
		bool isRegistered;
		uint8 statusCode;
		uint256 timestamp;
		address airline;
		string flight;
	}

	mapping(address => uint256) private voteAirlines;										// Mapping btw airline address and vote numbers
	mapping(address => bool) private airlineQueue;


	event AirlineQueued(address airline);

	/********************************************************************************************/
	/*                                       FUNCTION MODIFIERS                                 */
	/********************************************************************************************/

	// Modifiers help avoid duplication of code. They are typically used to validate something
	// before a function is allowed to be executed.

	/**
	* @dev Modifier that requires the "operational" boolean variable to be "true"
	*      This is used on all state changing functions to pause the contract in
	*      the event there is an issue that needs to be fixed
	*/
	modifier requireIsOperational()
	{
		 // Modify to call data contract's status
		require(operational, "Contract is currently not operational");
		_;  // All modifiers require an "_" which indicates where the function body will be added
	}

	/**
	* @dev Modifier that requires the "ContractOwner" account to be the function caller
	*/
	modifier requireContractOwner()
	{
		require(msg.sender == contractOwner, "Caller is not contract owner");
		_;
	}

	/**
	* @dev Modifier that checks that the address is a registered airline
	*/
	modifier isRegisteredAirline() {
		require(flightSuretyData.isAirlineRegistered(msg.sender), "FlightSuretyApp::isRegisteredAirline - This airline is not registered");
		_;
	}

	/**
	* @dev Modifier to check if a company can participate to the contract
	*/
	modifier isParticipatingAirline() {
		require(flightSuretyData.isAirlineParticipating(msg.sender), "FlightSuretyApp::isParticipatingAirline - This airline is not yet able to participate");
		_;
	}

	/********************************************************************************************/
	/*                                       CONSTRUCTOR                                        */
	/********************************************************************************************/

	/**
	* @dev Contract constructor
	*
	*/
	constructor(address contractData) public {
		contractOwner = msg.sender;
		flightSuretyData = IFlightSuretyData(contractData);
	}

	/********************************************************************************************/
	/*                                       UTILITY FUNCTIONS                                  */
	/********************************************************************************************/

	function isOperational() public view returns(bool) {
		return operational;  // Modify to call data contract's status
	}

	function setOperational(bool change) public requireContractOwner {
		operational = change;  // Modify to call data contract's status
	}

	/********************************************************************************************/
	/*                                     SMART CONTRACT FUNCTIONS                             */
	/********************************************************************************************/

	/**
	 * @dev Add an airline to the registration queue
	 * @return success bool representing if the airline has been added to the queue
	 * @return votes uint256 number of votes the airline has
	*/
	function queueAirline() public requireIsOperational {
		// We can't queue an airline before 4 airlines are registered
		require(flightSuretyData.getNumberRegisteredAirlines() >= 4, "FlightSuretyApp::registerAirline - Can't add an airline to the registering queue since we don't yet have 4 airlines registered");
		require(!flightSuretyData.isAirlineRegistered(msg.sender), "FlightSuretyApp::registerAirline - This airline is already registered");

		// Add the airline to the queue
		airlineQueue[msg.sender] = true;

		// Emit relative event
		emit AirlineQueued(msg.sender);
	}

	/**
	* @dev A registered airline can vote for an airline that is in the queue
	*/
	function voteAirline(address airline) public isParticipatingAirline requireIsOperational returns(uint256) {
		require(airlineQueue[airline], "FlightSuretyApp::voteAirline - This airline is not in the queue");

		voteAirlines[airline] = voteAirlines[airline].add(1);
		// If the number of votes is greater than 50% we must approve the airline
		if(voteAirlines[airline] > flightSuretyData.getNumberRegisteredAirlines().div(2)){	
			flightSuretyData.registerAirline(airline);
		}
		else return voteAirlines[airline];

	}
	
	/**
	* @dev Add an airline
	* The first four airlines can be added by an existing airline
	*/
	function addAirline(address airline) public isParticipatingAirline requireIsOperational {
		require(flightSuretyData.getNumberRegisteredAirlines() < 4, "FlightSuretyApp::addAirline - Already 4 airlines have been added, you must pas by the queue process");
		flightSuretyData.registerAirline(airline);
	}

	/** 
	* @dev Submit funds to participate
	*/
	function submitFunds() public payable isRegisteredAirline requireIsOperational {
		require(msg.value >= MINIMUM_AIRLINE_FUNDING, "FlightSuretyApp::submitFunds - Funds are not enought to be able to participate");
		flightSuretyData.fund.value(msg.value)(msg.sender);
	}


	/**
	* @dev Register a future flight for insuring.
	* @param flight string the name of the flight
	* @param timestamp uint256 the timestamp of the flight
	*/
	function registerFlight(string calldata flight, uint256 timestamp) external requireIsOperational {
		flightSuretyData.registerFlight(flight, timestamp, msg.sender);
	}

	/**
	* @dev Get the list of flights number
	* @return bytes32[] array of flight numbers
	*/
	function getFlightKeys() public view returns(bytes32[] memory) {
		return flightSuretyData.getFlightKeys(); 
	}

	/**
	* @dev Called after oracle has updated flight status
	*
	*/
	function processFlightStatus(address airline, string memory flight, uint256 timestamp, uint8 statusCode) internal {
		flightSuretyData.processFlightStatus(airline, flight, timestamp, statusCode);
		flightSuretyData.creditInsurees(airline, flight, timestamp, 3, 2);
	}


	/**
	* @dev Generate a request for oracles to fetch flight information
	* @param airline address
	* @param flight string
	* @param timestamp uint256 of the flight
	*/
	function fetchFlightStatus (address airline, string calldata flight, uint256 timestamp) external requireIsOperational {
		uint8 index = getRandomIndex(msg.sender);

		// Generate a unique key for storing the request
		bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
		oracleResponses[key] = ResponseInfo({ requester: msg.sender, isOpen: true });

		emit OracleRequest(index, airline, flight, timestamp);
	}

	/**
	* @dev Get the status of a flight
	*/
	function getFlightStatus(address airline, string calldata flight, uint256 timestamp) external view returns(uint8 statusCode) {
		return flightSuretyData.getFlightStatus(airline, flight, timestamp);
	}

	/**
	* @dev Buy an insurance for a flight
	*/
	function buy(address airline, string calldata flight, uint256 timestamp) external payable requireIsOperational {
		require(msg.value > 0, "You must provide some fund to buy an insurance");
		require(msg.value <= MAXIMUM_INSURANCE, "You can buy an insurance only up to 1 ether");
		
		// We check that event with this amount and the funds he already provided, the passenger won't go over the MAXIMUM_INSURANCE amount
		uint256 insuranceFund = flightSuretyData.getInsuranceFundAmount(airline, flight, timestamp, msg.sender);
		uint256 futurAmount = insuranceFund.add(msg.value);
		require(futurAmount <= MAXIMUM_INSURANCE, "You can buy an insurance only up to 1 ether");

		flightSuretyData.buy.value(msg.value)(airline, flight, timestamp, msg.sender);
	}

	function getInsuranceFundAmount(address airline, string calldata flight, uint256 timestamp) external view returns(uint256) {
		return flightSuretyData.getInsuranceFundAmount(airline, flight, timestamp, msg.sender);
	}

	function getFundsAvailable() external view returns(uint256) {
		return flightSuretyData.fundsAvailable(msg.sender);
	}

	function pay() external {
		flightSuretyData.pay(msg.sender);
	}


	// region ORACLE MANAGEMENT

	// Incremented to add pseudo-randomness at various points
	uint8 private nonce = 0;

	// Fee to be paid when registering oracle
	uint256 public constant REGISTRATION_FEE = 1 ether;

	// Number of oracles that must respond for valid status
	uint256 private constant MIN_RESPONSES = 3;


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
	function registerOracle() external payable returns(uint8[3] memory) {
		// Require registration fee
		require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

		uint8[3] memory indexes = generateIndexes(msg.sender);

		oracles[msg.sender] = Oracle({ isRegistered: true, indexes: indexes });

		return indexes;
	}

	function getMyIndexes() view external returns(uint8[3] memory) {
		require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

		return oracles[msg.sender].indexes;
	}




	// Called by oracle when a response is available to an outstanding request
	// For the response to be accepted, there must be a pending request that is open
	// and matches one of the three Indexes randomly assigned to the oracle at the
	// time of registration (i.e. uninvited oracles are not welcome)
	function submitOracleResponse(uint8 index, address airline, string calldata flight, uint256 timestamp, uint8 statusCode) external {
		require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");

		bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
		require(oracleResponses[key].isOpen, "Oracle Reponse is no more open, or parameters does not match an open Oracle Response");

		oracleResponses[key].responses[statusCode].push(msg.sender);

		// Information isn't considered verified until at least MIN_RESPONSES
		// oracles respond with the *** same *** information
		emit OracleReport(airline, flight, timestamp, statusCode);
		if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {
			emit FlightStatusInfo(airline, flight, timestamp, statusCode);
			// Close the Oracle response
			oracleResponses[key].isOpen = false;
			
			// Handle flight status as appropriate
			processFlightStatus(airline, flight, timestamp, statusCode);
		}
	}


	function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
		return keccak256(abi.encodePacked(airline, flight, timestamp));
	}

	// Returns array of three non-duplicating integers from 0-9
	function generateIndexes(address account) internal returns(uint8[3] memory) {
		uint8[3] memory indexes;
		indexes[0] = getRandomIndex(account);

		indexes[1] = indexes[0];
		while(indexes[1] == indexes[0]) {
			indexes[1] = getRandomIndex(account);
		}

		indexes[2] = indexes[1];
		while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
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
			nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
		}

		return random;
	}

}
