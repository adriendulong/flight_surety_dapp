pragma solidity ^0.5.2;

interface IFlightSuretyData {
  function registerAirline(address airline) external;
  function getNumberRegisteredAirlines() external view returns(uint);
  function isAirlineRegistered(address airline) external view returns(bool);
  function fund(address airline) external payable;
  function isAirlineParticipating(address airline) external view returns(bool);
  function registerFlight(string calldata flight, uint256 timestamp, address airline) external;
  function getFlightKeys() external view returns(bytes32[] memory);
  function getFlightInfos(bytes32 flightKey) external view returns(uint8 statusCode, uint256 timestamp, address airline, string memory flight, bool insurancePaid, bytes32 key); 
  function processFlightStatus(address airline, string calldata flight, uint256 timestamp, uint8 statusCode) external;
  function getFlightStatus(address airline, string calldata flight, uint256 timestamp) external view returns(uint8 statusCode);
  function buy(address airline, string calldata flight, uint256 timestamp, address passenger) external payable;
  function getInsuranceFundAmount(address airline, string calldata flight, uint256 timestamp, address passenger) external view returns(uint256);
  function creditInsurees(address airline, string calldata flight, uint256 timestamp, uint8 creditNumerator, uint8 creditDenominator) external;
  function pay(address passenger) external;
  function fundsAvailable(address passenger) external view returns(uint256);
}