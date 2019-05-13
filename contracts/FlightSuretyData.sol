pragma solidity ^0.5.2;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./interfaces/IFlightSuretyData.sol";

contract FlightSuretyData is IFlightSuretyData {
	using SafeMath for uint256;

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

	struct Flight {
		bool isRegistered;
		uint8 statusCode;
		uint256 timestamp;
		address airline;
		string flight;
		bool insurancePaid;
	}


	address private contractOwner;                                      // Account used to deploy contract
	bool private operational = true;                                    // Blocks all state changes throughout the contract if false
	uint public countRegisteredAirlines = 0;													// A counter of registered airlines
	mapping(address => bool) private registeredAirlines;						// Registered airlines
	mapping(address => uint) private partipatingAirlines;						// Airlines that have funds the smart contract and are able to participate
	mapping(address => uint) private authorizedContracts;						// Contracts authorized to call this one
	mapping(bytes32 => Flight) private flights;
	mapping(address => mapping(bytes32 => uint256)) private passengerAssurances;
	mapping(bytes32 => address[]) private flightInsurees;
	mapping(address => uint256) private passengerFunds;


	bytes32[] public flightKeys;

	event AirlineRegistered(address airline, uint countAirlines);
	event AirlineParticipating(address airline, uint participation);
	event FlightAdded(bytes32 flightKey, address airline, string flight);
	event BalanceChanged(address passenger);
	/********************************************************************************************/
	/*                                       EVENT DEFINITIONS                                  */
	/********************************************************************************************/


	/**
	* @dev Constructor
	* The deploying account becomes contractOwner
	*/
	constructor(address firstAirline) public {
		contractOwner = msg.sender;

		// Add the first airline
		_registerAirline(firstAirline);
		_registerFlight("AD001", block.timestamp, firstAirline);
		_registerFlight("AD002", block.timestamp, firstAirline);
		_registerFlight("AD003", block.timestamp, firstAirline);
		_registerFlight("AD004", block.timestamp, firstAirline);
	}

	/********************************************************************************************/
	/*                                       FUNCTION MODIFIERS                                 */
	/********************************************************************************************/

	/**
	* @dev Modifier that requires the "operational" boolean variable to be "true"
	*      This is used on all state changing functions to pause the contract in 
	*      the event there is an issue that needs to be fixed
	*/
	modifier requireIsOperational() 
	{
		require(operational, "Contract is currently not operational");
		_;  // All modifiers require an "_" which indicates where the function body will be added
	}

	/**
	* @dev Modifier that requires the "ContractOwner" account to be the function caller
	*/
	modifier requireContractOwner() {
		require(msg.sender == contractOwner, "Caller is not contract owner");
		_;
	}

	modifier requireIsCallerAuthorized() {
    require(authorizedContracts[msg.sender] == 1, "Caller is not contract owner");
    _;
  }

	/**
	* @dev Modifier that checks that an airline is registered
	*/
	modifier isRegisteredAirline(address airline) {
		 require(registeredAirlines[airline], "FlightSuretyData::isRegisteredAirline: This airline is not registered");
		 _;
	}

	/**
	* @dev Modifier that checks that an airline is registered
	*/
	modifier needAirlineParticipating(address airline) {
		 require(partipatingAirlines[airline] != 0, "FlightSuretyData::needAirlineParticipating: This airline is not yet able to participate");
		 _;
	}

	/********************************************************************************************/
	/*                                       UTILITY FUNCTIONS                                  */
	/********************************************************************************************/

	function authorizeContract(address contractAddress) public requireContractOwner {
    authorizedContracts[contractAddress] = 1;
  }

	/**
	* @dev Get operating status of contract
	*
	* @return A bool that is the current operating status
	*/      
	function isOperational() public view returns(bool) {
		return operational;
	}


	/**
	* @dev Sets contract operations on/off
	*
	* When operational mode is disabled, all write transactions except for this one will fail
	*/    
	function setOperatingStatus(bool mode) external requireContractOwner {
		operational = mode;
	}

	/**
	* @dev Add an airline to the registered ones
	*/
	function _registerAirline(address airline) internal requireIsOperational {
		registeredAirlines[airline] = true;
		countRegisteredAirlines = countRegisteredAirlines.add(1);
		emit AirlineRegistered(airline, countRegisteredAirlines);
	}

	/********************************************************************************************/
	/*                                     SMART CONTRACT FUNCTIONS                             */
	/********************************************************************************************/

	/**
	* @dev Get number of registered airlines
	*/
	function getNumberRegisteredAirlines() external view requireIsCallerAuthorized returns(uint){
		return countRegisteredAirlines;
	}

	/**
	* @dev Add an airline to the registration queue
	*      Can only be called from FlightSuretyApp contract
	*
	*/   
	function registerAirline(address airline) external requireIsCallerAuthorized {
		_registerAirline(airline);
	}

	/**
	* @dev Tell if an airline is registered or not
	* @param airline address of the airline we want to know about
	*/
	function isAirlineRegistered(address airline) external view requireIsCallerAuthorized returns(bool){
		return (registeredAirlines[airline]);
	}

	/** 
	* @dev Let airline funds the smart contract
	* @param airline address of the airline that funds the smart contract
	*/
	function fund(address airline) external payable isRegisteredAirline(airline) requireIsCallerAuthorized requireIsOperational {
		partipatingAirlines[airline] = msg.value;
		emit AirlineParticipating(airline, msg.value);
	}

	/**
	* @dev Tell if an airline can participate
	* @param airline address of the airline we want to know about
	*/
	function isAirlineParticipating(address airline) external view requireIsCallerAuthorized returns(bool){
		return (partipatingAirlines[airline] != 0);
	}

	/*************************************/
	/********** FLIGHT FUNCTIONS *********/
	/*************************************/

	/**
	* @dev Register a future flight for insuring.
	* @param flight string the name of the flight
	* @param timestamp uint256 flight timestamp
	* @param airline address the address of the airline that register this flight
	*/

	function registerFlight(string calldata flight, uint256 timestamp, address airline) external requireIsCallerAuthorized requireIsOperational needAirlineParticipating(airline) {
		_registerFlight(flight, timestamp, airline);
	}


	/**
	* @dev Internal function that create a flight and check that it does not already exists
	* @param flight string Flight name
	* @param timestamp uint256 Flight time
	* @param airline address Airline that creates the flight
	*/
	function _registerFlight(string memory flight, uint256 timestamp, address airline) internal {
		bytes32 flightKey = getFlightKey(airline, flight, timestamp);
		require(!flights[flightKey].isRegistered, "FlightSuretyData::registerFlight - This flight is already registered");
		// Create a new Flight
		flights[flightKey] = Flight({
			isRegistered: true,
			statusCode: STATUS_CODE_UNKNOWN,
			timestamp: timestamp,
			flight: flight,
			airline: airline,
			insurancePaid: false
		});
		// Add the flight Number to the flight number array
		flightKeys.push(flightKey);

		emit FlightAdded(flightKey, airline, flight);
	}

	/**
	* @dev Get the list of flights number
	* @return bytes32[] array of flight numbers
	*/
	function getFlightKeys() external view requireIsCallerAuthorized returns(bytes32[] memory) {
		return flightKeys;
	}

		/**
	* @dev Get the infos of a flight
	* @return bytes32[] array of flight numbers
	*/
	function getFlightInfos(bytes32 flightKey) external view requireIsCallerAuthorized returns(
		uint8 statusCode,
		uint256 timestamp,
		address airline,
		string memory flight,
		bool insurancePaid,
		bytes32 key
	) 
	{
		return (flights[flightKey].statusCode, flights[flightKey].timestamp, flights[flightKey].airline, flights[flightKey].flight, flights[flightKey].insurancePaid, flightKey);
	}

	/**
	* @dev Process the flight status
	* @param airline address of the airline
	* @param flight string name of the flight
	* @param timestamp uint256 time of the flight
	* @param statusCode uint8 Status of the flight
	*/
	function processFlightStatus(address airline, string calldata flight, uint256 timestamp, uint8 statusCode) external requireIsCallerAuthorized requireIsOperational {
		bytes32 flightKey = getFlightKey(airline, flight, timestamp);
		flights[flightKey].statusCode = statusCode;
	}

	/**
	* @dev Get flight status
	* @param airline address of the airline
	* @param flight string name of the flight
	* @param timestamp uint256 time of the flight
	*/
	function getFlightStatus(address airline, string calldata flight, uint256 timestamp) external view requireIsCallerAuthorized returns(uint8 statusCode) {
		bytes32 flightKey = getFlightKey(airline, flight, timestamp);
		return flights[flightKey].statusCode;
	}


	/**
	* @dev Buy insurance for a flight
	*
	*/   
	function buy(address airline, string calldata flight, uint256 timestamp, address passenger) external payable requireIsCallerAuthorized {
		bytes32 flightKey = getFlightKey(airline, flight, timestamp);
		passengerAssurances[passenger][flightKey] = passengerAssurances[passenger][flightKey].add(msg.value);
		flightInsurees[flightKey].push(passenger);
	}

	/**
	* Function that returns the amount of funds a passenger has put in a flight insurance
	*/
	function getInsuranceFundAmount(address airline, string calldata flight, uint256 timestamp, address passenger) external view requireIsCallerAuthorized returns(uint256) {
		bytes32 flightKey = getFlightKey(airline, flight, timestamp);
		return passengerAssurances[passenger][flightKey];
	}

	/**
	*  @dev Credits payouts to insurees
	*/
	function creditInsurees(address airline, string calldata flight, uint256 timestamp, uint8 creditNumerator, uint8 creditDenominator) external requireIsCallerAuthorized {
		bytes32 flightKey = getFlightKey(airline, flight, timestamp);
		require(!flights[flightKey].insurancePaid, "Funds for this flight have already been paid");

		for (uint i = 0; i < flightInsurees[flightKey].length; i++) {
			address passenger = flightInsurees[flightKey][i];
			uint256 insuranceAmount = passengerAssurances[passenger][flightKey];

			// Calcule the amount the insuree must be credited
			uint256 amountToPay = insuranceAmount.mul(creditNumerator).div(creditDenominator);
			// add funds to the passenger that subscribed an insurance
			passengerFunds[flightInsurees[flightKey][i]] = passengerFunds[flightInsurees[flightKey][i]].add(amountToPay);

			emit BalanceChanged(passenger);

			// set the amount of the insurance to 0 for this passenger
			passengerAssurances[passenger][flightKey] = 0;
		}

		// Delete the array that list all the passenger that took an insurance for the flight
		delete flightInsurees[flightKey];
	}

	/**
	* @dev Function that returns the funds a user can withdraw anytime he wants
	*/
	function fundsAvailable(address passenger) external view requireIsCallerAuthorized returns(uint256) {
		return passengerFunds[passenger];
	}
		

	/**
	 *  @dev Transfers eligible payout funds to insuree
	 *
	*/
	function pay(address passenger) external requireIsCallerAuthorized {
		require(passengerFunds[passenger] > 0, "This passenger has no funds");
		address payable passengerPayable = address(uint160(bytes20(passenger)));
		uint256 toPay = passengerFunds[passenger];
		delete passengerFunds[passenger];
		passengerPayable.transfer(toPay);
	}

	function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
		return keccak256(abi.encodePacked(airline, flight, timestamp));
	}

	// /**
	// * @dev Fallback function for funding smart contract.
	// *
	// */
	// function() external payable {
	// 	fund();
	// }


}

