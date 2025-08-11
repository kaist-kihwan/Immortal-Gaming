// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title IGToken
 * @dev ERC20 token used as the exclusive currency for ItemToken transactions.
 * Minting and burning are restricted to accounts with the MODERATOR_ROLE.
 */
contract IGToken is ERC20, AccessControl, ERC20Burnable {
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    constructor() ERC20("In-Game Token", "IGT") {
        // Grant the contract deployer the default admin role and the moderator role.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MODERATOR_ROLE, msg.sender);
    }

    /**
     * @notice 관리자가 특정 주소에 moderator 역할을 부여합니다.
     * @dev 이 함수는 DEFAULT_ADMIN_ROLE을 가진 주소만 호출할 수 있습니다.
     * @param account 역할을 부여할 주소
     */
    function grantModerator(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MODERATOR_ROLE, account);
    }

    /**
     * @notice 관리자가 특정 주소에서 moderator 역할을 박탈합니다.
     * @dev 이 함수는 DEFAULT_ADMIN_ROLE을 가진 주소만 호출할 수 있습니다.
     * @param account 역할을 박탈할 주소
     */
    function revokeModerator(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MODERATOR_ROLE, account);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     * Can only be called by accounts with the MODERATOR_ROLE.
     */
    function mint(address to, uint256 amount) public onlyRole(MODERATOR_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev Overrides the ERC20Burnable `burnFrom` to restrict its usage.
     * While `burn` allows users to burn their own tokens, `burnFrom`
     * could be used by an approved party. Here we restrict it to moderators.
     * Can only be called by accounts with the MODERATOR_ROLE.
     */
    function burnFrom(address account, uint256 amount) public override onlyRole(MODERATOR_ROLE) {
        _burn(account, amount);
    }
}