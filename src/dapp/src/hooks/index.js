import { useMemo, useState, useEffect } from 'react'
import { useWeb3Context } from 'web3-react'

import FLIGHT_SURETY_APP_ABI from '../abi/app'
import FLIGHT_SURETY_DATA_ABI from '../abi/data'
import Config from '../config';

import { getContract } from '../utils'

// returns null on errors
export function useAppContract() {
  const { library, account } = useWeb3Context()

  return useMemo(() => {
    try {
      return getContract(Config.localhost.appAddress, FLIGHT_SURETY_APP_ABI, library, account)
    } catch (e){
      console.error(e.message)
      return null
    }
  }, [library, account])
}

// returns null on errors
export function useDataContract() {
  const { library, account } = useWeb3Context()

  return useMemo(() => {
    try {
      return getContract(Config.localhost.dataAddress, FLIGHT_SURETY_DATA_ABI, library, account)
    } catch (e){
      console.error(e.message)
      return null
    }
  }, [library, account])
}

/**
 * Custom hook that fetch the flights
 */
export function useFetchFlights() {
  const appContract = useAppContract()
  const [flights, setFlights] = useState([]);
  const [error, setError] = useState();

  async function getFlights() {
    try {
      const flightKeys = await appContract.getFlightKeys()

      //Iterate over keys to get the details of each flight
      let flights = []
      for(let key of flightKeys) {
        const flight = await appContract.getFlightInfos(key)
        flights.push(flight)
      }

      // Update state
      setFlights(flights)
    }
    catch (e) {
      setError(e)
      console.error(e)
    }
  }

  useEffect(() => {
    getFlights()
  }, []);

  return { flights, error }
}