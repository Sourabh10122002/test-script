// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {
    FlashLoanSimpleReceiverBase
} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {
    IPoolAddressesProvider
} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {
    IERC20
} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

/**
 * @title FlashUsdtSepolia
 * @dev A legitimate Aave V3 Flash Loan simple receiver skeleton for use on Sepolia.
 *
 * Sepolia Aave V3 PoolAddressesProvider: 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A
 * Sepolia USDT mock token: 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0 (Aave's faucet USDT)
 */
contract FlashUsdtSepolia is FlashLoanSimpleReceiverBase {
    address payable owner;

    constructor(
        address _addressProvider
    ) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) {
        owner = payable(msg.sender);
    }

    /**
     * @dev This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address /* initiator */,
        bytes calldata /* params */
    ) external override returns (bool) {
        // -----------------------------------------------------------------------
        // This contract now has the requested funds.
        //
        // Add your custom logic here (e.g. arbitrage, liquidations, etc.).
        //
        // Note: At the end of this function, the contract MUST have enough
        // of `asset` token balance to pay back the `amount + premium`.
        // -----------------------------------------------------------------------

        uint256 amountOwed = amount + premium;

        // Approve the Pool contract to pull the owed amount from this contract
        IERC20(asset).approve(address(POOL), amountOwed);

        return true;
    }

    /**
     * @dev Check the balance of any ERC20 token (like USDT) in this contract.
     * In Remix, simply call this with the token address.
     */
    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    /**
     * @dev Specifically check the balance of Sepolia testnet USDT.
     * Hardcoded Sepolia USDT Mock: 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0
     */
    function getUsdtBalance() external view returns (uint256) {
        address usdtAddress = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;
        return IERC20(usdtAddress).balanceOf(address(this));
    }

    /**
     * @dev Initiates a flash loan
     */
    function requestFlashLoan(address _token, uint256 _amount) public {
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;

        // Call the flashLoanSimple method on the Aave V3 Pool
        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );
    }

    /**
     * @dev Simple withdraw function allowing the owner to withdraw token balances
     */
    function withdraw(address _tokenAddress) external {
        require(msg.sender == owner, "Only owner can withdraw");
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /**
     * @dev Withdraw native ETH accumulated
     */
    function withdrawEth() external {
        require(msg.sender == owner, "Only owner can withdraw");
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }

    receive() external payable {}
}
