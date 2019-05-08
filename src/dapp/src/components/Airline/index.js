import React, { useState, useEffect } from 'react';
import { useWeb3Context } from 'web3-react'
import { ethers } from 'ethers';

import { useAppContract } from '../../hooks'

import './airline.css'

function Airline() {
  const [gas, setGas] = useState(0);
  const appContract = useAppContract()

  async function estimateGas() {
    const gasEstimation = await appContract.estimate.registerOracle({value: ethers.utils.parseEther("2")})
    console.log(gasEstimation.toString())
    setGas(gasEstimation.toString());
  }

  useEffect(() => {
    estimateGas();
  }, []);

  return (
    <div>
      <p>Airline</p>
      <p>{gas}</p>
    </div>
  )
}

export default Airline