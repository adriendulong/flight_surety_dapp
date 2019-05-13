import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useWeb3Context } from 'web3-react'

import { useAppContract, useDataContract } from '../../hooks'

import './check-balance.css'

export default function CheckBalance() {
  const { account } = useWeb3Context()
  const appContract = useAppContract()
  const dataContract = useDataContract()
  const [balance, setBalance] = useState()
  const [isUpdated, setIsUpdated] = useState(false)

  // Listen the event that let us know the balance of the passenger changed
  // Update the balance when it has changed
  dataContract.on('BalanceChanged', (address, event) => {
    if(address == account) getBalance(updatedBalance)
  })

  async function getBalance(callback) {
    let balance = await appContract.getFundsAvailable()
    setBalance(ethers.utils.formatEther(balance.toString()))
    if(callback) callback()
  }

  async function withdraw(e) {
    e.preventDefault()
    try {
      await appContract.pay()
      getBalance()
    }
    catch (e) {
      console.error(e)
    }
  }

  function updatedBalance() {
    setIsUpdated(true)
    setTimeout(() => {
      setIsUpdated(false)
    }, 2000)
  }

  useEffect(() => {
    getBalance()
  })

  return (
    <div id="check-balance">
      {isUpdated && (
        <h3 id='balance-updated'>Your balance (BALANCE UPDATED!)</h3>
      )}
      {!isUpdated && (
        <h3>Your balance</h3>
      )}
      {balance && (
        <p>{balance} ETH</p>
      )}
      <button onClick={withdraw}>Withdraw</button>
    </div>
  )
}