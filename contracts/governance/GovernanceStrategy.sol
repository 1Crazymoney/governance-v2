// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import {IGovernanceStrategy} from '../interfaces/IGovernanceStrategy.sol';
import {IERC20} from '../interfaces/IERC20.sol';
import {IDelegationAwareToken} from '../interfaces/IDelegationAwareToken.sol';

/**
 * @title Governance Strategy contract
 * @dev Smart contract containing logic to measure users' relative power to propose and vote.
 * User Power = User Power from Aave Token + User Power from stkAave Token.
 * User Power from Token = Token Power + Token Power as Delegatee [- Token Power if user has delegated]
 * Two wrapper functions linked to Aave Tokens's GovernancePowerDelegationERC20.sol implementation
 * - getPropositionPowerAt: fetching a user Proposition Power at a specified block
 * - getVotingPowerAt: fetching a user Voting Power at a specified block
 * @author Aave
 **/
contract GovernanceStrategy is IGovernanceStrategy {
  address public immutable AAVE;
  address public immutable STK_AAVE;

  /**
   * @dev Constructor, register tokens used for Voting and Proposition Powers.
   * @param aave The address of the AAVE Token contract.
   * @param stkAave The address of the stkAAVE Token Contract
   **/
  constructor(address aave, address stkAave) {
    AAVE = aave;
    STK_AAVE = stkAave;
  }

  /**
   * @dev Returns the total supply of Outstanding Proposition Tokens 
   * Outstanding Tokens = Outstanding AAVE       + Outstanding stkAAVE
   * Outstanding Tokens = # AAVE - # staked AAVE + # stkAAVE 
   * Outstanding Tokens = # AAVE
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalPropositionSupplyAt(uint256 blockNumber) public view override returns (uint256) {
    // The AAVE locked in the stkAAVE is not taken into account, so the calculation is:
    //  aggregatedSupply = aaveSupply + stkAaveSupply - aaveLockedInStkAave
    // As aaveLockedInStkAave = stkAaveSupply => aggregatedSupply = aaveSupply + stkAaveSupply - stkAaveSupply = aaveSupply
    return IERC20(AAVE).totalSupplyAt(blockNumber);
  }

  /**
   * @dev Returns the total supply of Outstanding Voting Tokens 
   * Outstanding Tokens = Outstanding AAVE       + Outstanding stkAAVE
   * Outstanding Tokens = # AAVE - # staked AAVE + # stkAAVE 
   * Outstanding Tokens = # AAVE
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalVotingSupplyAt(uint256 blockNumber) public view override returns (uint256) {
    return getTotalPropositionSupplyAt(blockNumber);
  }

  /**
   * @dev Returns the Proposition Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Proposition Power
   * @return Power number
   **/
  function getPropositionPowerAt(address user, uint256 blockNumber)
    public
    view
    override
    returns (uint256)
  {
    return
      _getPowerByTypeAt(user, blockNumber, IDelegationAwareToken.DelegationType.PROPOSITION_POWER);
  }

  /**
   * @dev Returns the Vote Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Vote Power
   * @return Vote number
   **/
  function getVotingPowerAt(address user, uint256 blockNumber)
    public
    view
    override
    returns (uint256)
  {
    return _getPowerByTypeAt(user, blockNumber, IDelegationAwareToken.DelegationType.VOTING_POWER);
  }

  function _getPowerByTypeAt(
    address user,
    uint256 blockNumber,
    IDelegationAwareToken.DelegationType powerType
  ) internal view returns (uint256) {
    return
      IDelegationAwareToken(AAVE).getPowerAtBlock(user, blockNumber, powerType) +
      IDelegationAwareToken(STK_AAVE).getPowerAtBlock(user, blockNumber, powerType);
  }
}
