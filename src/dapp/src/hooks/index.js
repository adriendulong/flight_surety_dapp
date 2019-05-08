import { useMemo, useCallback, useEffect } from 'react'
import { useWeb3Context } from 'web3-react'

import FLIGHT_SURETY_APP_ABI from '../abi/app'
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