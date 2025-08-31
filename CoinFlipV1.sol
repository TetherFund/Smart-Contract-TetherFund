// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CoinFlipGame is Ownable {
    IERC20 public token;
    uint256 public minimumBet = 1 * 10**18;
    uint256 private nonce;

    enum Side { Heads, Tails }

    event GameResult(address indexed player, bool win, uint256 amountWon, Side choice, Side result);

    constructor(address _tokenAddress) Ownable(msg.sender) {
        token = IERC20(_tokenAddress);
    }

    function flipCoin(Side _choice, uint256 amount, uint256 multiplier) external {
        require(amount >= minimumBet, "Apuesta muy baja");
        require(token.allowance(msg.sender, address(this)) >= amount, "Approve insuficiente");
        require(multiplier >= 1 && multiplier <= 100, "Multiplicador invalido");

        require(token.transferFrom(msg.sender, address(this), amount), "Transferencia fallida");

        nonce++;
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 10000;

        uint256 chance = getWinChance(multiplier);
        require(chance > 0, "Multiplicador no admitido");

        bool win = rand < chance;
        Side result = win ? _choice : (_choice == Side.Heads ? Side.Tails : Side.Heads);

        uint256 payout = 0;

        if (win) {
            payout = amount * multiplier;
            require(token.balanceOf(address(this)) >= payout, "Contrato sin fondos");
            token.transfer(msg.sender, payout);
        }

        emit GameResult(msg.sender, win, payout, _choice, result);
    }

    function getWinChance(uint256 multiplier) public pure returns (uint256) {
        if (multiplier == 1) return 2000;   
        if (multiplier == 2) return 1800;   
        if (multiplier == 5) return 1400;   
        if (multiplier == 20) return 1000;  
        if (multiplier == 25) return 800; 
        if (multiplier == 50) return 500;  
        if (multiplier == 100) return 300;
        return 0;
    }

    // --- Admin ---
    function withdraw(uint256 amount) external onlyOwner {
        require(token.transfer(msg.sender, amount), "Retiro fallido");
    }

    function setMinimumBet(uint256 _amount) external onlyOwner {
        minimumBet = _amount;
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }
}
