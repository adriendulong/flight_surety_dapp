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
	}

	address private contractOwner;                                      // Account used to deploy contract
	bool private operational = true;                                    // Blocks all state changes throughout the contract if false
	uint public countRegisteredAirlines = 0;													// A counter of registered airlines
	mapping(address => bool) private registeredAirlines;						// Registered airlines
	mapping(address => uint) private partipatingAirlines;						// Airlines that have funds the smart contract and are able to participate
	mapping(address => uint) private authorizedContracts;						// Contracts authorized to call this one
	mapping(bytes32 => Flight) private flights;

	bytes32[] public flightKeys;

	event AirlineRegistered(address airline, uint countAirlines);
	event AirlineParticipating(address airline, uint participation);
	event FlightAdded(bytes32 flightKey, address airline, string flight);
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
	function _registerAirline(address airline) internal {
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
	function fund(address airline) external payable isRegisteredAirline(airline) requireIsCallerAuthorized {
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

	function registerFlight(string calldata flight, uint256 timestamp, address airline) external requireIsCallerAuthorized needAirlineParticipating(airline) {
		bytes32 flightKey = getFlightKey(airline, flight, timestamp);
		require(!flights[flightKey].isRegistered, "FlightSuretyData::registerFlight - This flight is already registered");
		// Create a new Flight
		flights[flightKey] = Flight({
			isRegistered: true,
			statusCode: STATUS_CODE_UNKNOWN,
			timestamp: timestamp,
			flight: flight,
			airline: airline
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


// 	/**
// 	* @dev Buy insurance for a flight
// 	*
// 	*/   
// 	function buy() external payable {
// 	}

// 	/**
// 	*  @dev Credits payouts to insurees
// 	*/
// 	function creditInsurees() external pure {
// 	}
		

// 	/**
// 	 *  @dev Transfers eligible payout funds to insuree
// 	 *
// 	*/
// 	function pay() external pure {
// 	}

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

