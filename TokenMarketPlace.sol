// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenMarketPlace{
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    //
    uint public tokenPrice= 2e16 wei;
    uint public sellerCount=1;
    uint public buyerCount;

    IERC20 public gldToken;

    event TokenPriceUpdated(uint newPrice);
    event TokenBought(address indexed buyer, uint amount, uint tokenPrice);
    event TokenSold(address indexed seller, uint amount, uint tokenPrice);

    constructor(address _erc20Token){
        gldToken=IERC20(_erc20Token);

    }

    function calculateTokenPrice() public {
        //tokenPrice = tokenPrice*(buyer/(seller+buyer))
        //buyer=1 seller=1 tokenPrice = tokenPrice(1/(2))
        // tokenPrice=tokenPrice*(buyerCount/(sellerCount+buyerCount));

        //using the safemath library
        require(buyerCount!=0,"There must be 1 buyer");
        uint totalParticipants = sellerCount.add(buyerCount);
       // uint ratioOfBuyerSeller = buyerCount.div(totalParticipants);
        //tokenPrice = tokenPrice.mul(ratioOfBuyerSeller);
        tokenPrice = (tokenPrice.mul(buyerCount)).div(totalParticipants);
        emit TokenPriceUpdated(tokenPrice);
    }

    function buyGLDToken(uint amountOfToken) public payable {
        uint priceToPay = tokenPrice*(amountOfToken.div(1e18)); //2e16 wei* 10*10^18
        require(msg.value==priceToPay,"ethers not enough");
        gldToken.safeTransfer(msg.sender,amountOfToken);
        buyerCount=buyerCount.add(1);
        emit TokenBought(msg.sender, amountOfToken, tokenPrice);
    }

    function sellGLDToken(uint amountOfToken) public payable{
        require(gldToken.balanceOf(msg.sender)>=amountOfToken,"not enough token");
        uint amountToPayTheUser = tokenPrice*(amountOfToken.div(1e18));
        gldToken.safeTransferFrom(msg.sender,address(this),amountOfToken);
        (bool success,)=msg.sender.call{value:amountToPayTheUser}("");
        require(success, "Transfer Failed");
        sellerCount=sellerCount.add(1);
    }

    fallback() external payable {

     }

    receive() external payable {
        
     }
    
}