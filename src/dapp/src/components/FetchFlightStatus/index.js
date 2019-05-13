import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';

import { useAppContract, useFetchFlights } from '../../hooks'

import './fetch-flight-status.css'

function FetchFlightStatus() {
  const appContract = useAppContract()
  const [selectedFlight, setSelectedFlight] = useState();
  const { flights, error } = useFetchFlights()
    
  async function fetchStatus(e){
    e.preventDefault()
    console.log("Fetch")
    let flight = flights[parseInt(selectedFlight)]
    await appContract.fetchFlightStatus(flight.airline, flight.flight, flight.timestamp.toString())
  }

  useEffect(() => {
    if(flights) setSelectedFlight('0')
  }, [flights])

  return (
    <div id="flight-status">
      <h3>Fetch flight status</h3>
      <form className="column-form">
        <label htmlFor="selectFlight">Choose a flight: </label>
        {selectedFlight && (
          <select id="selectFlight" value={selectedFlight} onChange={(e) => setSelectedFlight(e.target.value)}>
            {flights.map((flight, index) => (
              <option value={index} key={index}>
                {flight.flight}
              </option>
            ))}
          </select>
        )}
        {error && (
          <p>{error.message}</p>
        )}
        <button onClick={fetchStatus}>Fetch flight status</button>
      </form>
    </div>
  )
}

export default FetchFlightStatus