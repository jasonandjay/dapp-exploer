// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IFlashLoanSimpleReceiver} from "@aave/core-v3/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./UniswapV2.sol";


interface IFaucet {
    function mint(address _token, uint256 _amount) external;
}

abstract contract FlashLoanSimpleReceiverBase is IFlashLoanSimpleReceiver {
    IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
    IPool public immutable override POOL;
    IFaucet public immutable FAUCET;

    constructor(IPoolAddressesProvider provider, IFaucet faucet) {
        ADDRESSES_PROVIDER = provider;
        POOL = IPool(provider.getPool());
        FAUCET = faucet;
    }
}

contract SWapFlashLoanV3 is FlashLoanSimpleReceiverBase {

    // DAI 合约地址
    address public dai = 0xDF1742fE5b0bFc12331D8EAec6b478DfDbD31464;
    // TokenA 合约地址
    address public tokenA = 0x819CB18AfbE21915fbdA5B4B953ab819f2d69D56;
    // TokenB 合约地址
    address public tokenB = 0x4B5eE10e58709cE40AA254c5B757c1e2b6a94152;
    // Uniswap V2 路由地址
    address public router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    constructor(IPoolAddressesProvider _addressProvider, IFaucet _faucet)
        FlashLoanSimpleReceiverBase(_addressProvider, _faucet)
    {}

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // Logic go here.

         // approve DAI
        IERC20(dai).approve(router, 2**256-1);
        // swap path: DAI => TokenA
        address[] memory daiToTka = new address[](2);
        daiToTka[0] = dai;
        daiToTka[1] = tokenA;
        // swap
        uint256 amountA = IUniswapV2Router(router).swapExactTokensForTokens(
            amount,
            0,
            daiToTka,
            address(this),
            block.timestamp
        )[1];

        // approve TokenA
        IERC20(tokenA).approve(router, 2**256-1);
        // swap path: TokenB => TokenA
        address[] memory tkaToTkb = new address[](2);
        tkaToTkb[0] = tokenA;
        tkaToTkb[1] = tokenB;

        // swap
        uint256 amountB = IUniswapV2Router(router).swapExactTokensForTokens(
            amountA,
            0,
            tkaToTkb,
            address(this),
            block.timestamp
        )[1];

        // approve TokenB
        IERC20(tokenB).approve(router, 2**256-1);
        // swap path: TokenA => DAI
        address[] memory tkbToDai = new address[](2);
        tkbToDai[0] = tokenB;
        tkbToDai[1] = dai;
        // swap
        uint256 amountDai = IUniswapV2Router(router).swapExactTokensForTokens(
            amountB,
            0,
            tkbToDai,
            address(this),
            block.timestamp
        )[1];


        // Approve the LendingPool contract allowance to *pull* the owed amount
        uint256 amountOwed = amount + premium;
        if (amountDai < amountOwed ){
            FAUCET.mint(asset, amountOwed - amountDai );
        }else{
            IERC20(asset).transfer(tx.origin, amountDai - amountOwed);
        }
        IERC20(asset).approve(address(POOL), amountOwed);


        return true;
    }

    function executeFlashLoan(address asset, uint256 amount) public {
        address receiverAddress = address(this);

        bytes memory params = "";
        uint16 referralCode = 0;

        POOL.flashLoanSimple(receiverAddress, asset, amount, params, referralCode);
    }
}