pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface ICirERC20 {
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function MINTER_ROLE (  ) external view returns ( bytes32 );
  function OPERATOR_ROLE (  ) external view returns ( bytes32 );
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function approveAndCall ( address spender, uint256 value ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function burn ( uint256 amount ) external;
  function burnFrom ( address account, uint256 amount ) external;
  function cap (  ) external view returns ( uint256 );
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function enableTransfer (  ) external;
  function finishMinting (  ) external;
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function getRoleMember ( bytes32 role, uint256 index ) external view returns ( address );
  function getRoleMemberCount ( bytes32 role ) external view returns ( uint256 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function mint ( address to, uint256 value ) external;
  function mintingFinished (  ) external view returns ( bool );
  function owner (  ) external view returns ( address );
  function recoverERC20 ( address tokenAddress, uint256 tokenAmount ) external;
  function renounceOwnership (  ) external;
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address to, uint256 value ) external returns ( bool );
  function transferAndCall ( address to, uint256 value ) external returns ( bool );
  function transferEnabled (  ) external view returns ( bool );
  function transferFrom ( address from, address to, uint256 value ) external returns ( bool );
  function transferFromAndCall ( address from, address to, uint256 value ) external returns ( bool );
  function transferOwnership ( address newOwner ) external;
}


interface ICompoundERC20 {
  function mint(uint mintAmount) external returns (uint);
  function redeemUnderlying(uint redeemAmount) external returns (uint);
  function borrow(uint borrowAmount) external returns (uint);
  function repayBorrow(uint repayAmount) external returns (uint);
  function borrowBalanceCurrent(address account) external returns (uint);
  function exchangeRateCurrent() external returns (uint);
  function transfer(address recipient, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint);
  function balanceOfUnderlying(address account) external view returns (uint);
  function decimals() external view returns (uint);
  function underlying() external view returns (address);
  function exchangeRateStored() external view returns (uint);
  function supplyRatePerBlock() external view returns (uint);
}

// Compound finance comptroller
interface IComptroller {
  function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
}
contract Circuit {
using SafeMath for uint256;
uint256 contractIssuedBalance;
uint256 initalPeg;
uint256 lastCoinPrice;
uint256 initalExchangeRate;
address admin;
uint256 internal constant PRECISION = 10 ** 18;
uint256 internal constant USDC_CONVERT_PRECISION = 10 ** 12;
uint256 internal constant USDC_PRECISION = 10 ** 6;
uint256 internal constant COMPOUND_PRECISION = 10 ** 8;

//ERC20 underLyingAsset USDC
 IERC20 underLyingAsset = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
 
  //Compound asset: cUSDC
 ICompoundERC20 compoundToken = ICompoundERC20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
 
 //Cream asset: cUSDC
 ICompoundERC20 creamToken = ICompoundERC20(0x44fbeBd2F576670a6C33f6Fc0B00aA8c5753b322);

 //CircuitYeildBearingAsset CIUSDC
 ICirERC20 circuitYeildToken = ICirERC20(0x51F559202fa6bf9B82828ECA194090acF6EB223f);
 
 //COMP TOKEN
 IERC20 compToken = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);
 
 

  constructor() public {
    admin = msg.sender;//admin is deployer
     initalPeg =1000000; //1 usdc
    lastCoinPrice = 0;
  }


    function estimatePrice() public view returns (uint256) {
       uint256 pricePerCoin=0;
        uint256 totalValue=0;
        if (contractIssuedBalance > initalPeg) {
        totalValue = (storedUnderlyingAssetValueCompound() + storedUnderlyingAssetValueCream());
        pricePerCoin = totalValue.mul(PRECISION).div(contractIssuedBalance);
        }else{
            pricePerCoin=initalPeg.mul(USDC_CONVERT_PRECISION);
        }

        return pricePerCoin;
    }
    

    function viewContractIssuedBalance() external view returns(uint) {
        return contractIssuedBalance;
      }
  
    function getTotalUnderlyingAssetValue() public view returns (uint256) {
      uint256 underlyingBalance;
      underlyingBalance = (storedUnderlyingAssetValueCompound() + storedUnderlyingAssetValueCream());
        return underlyingBalance;
    }
    
    function storedUnderlyingAssetValueCompound() public view returns (uint256) {
      uint256 exchangeRate;
      uint256 compoundTokenBalance;
      uint256 underlyingBalance;
      compoundTokenBalance = compoundToken.balanceOf(address(this));

      exchangeRate = compoundToken.exchangeRateStored();
      underlyingBalance = compoundTokenBalance.mul(exchangeRate).div(USDC_PRECISION);
        return underlyingBalance;
    }
    
    function storedUnderlyingAssetValueCream() public view returns (uint256) {
      uint256 exchangeRate;
      uint256 creamTokenBalance;
      uint256 underlyingBalance;
      creamTokenBalance = creamToken.balanceOf(address(this));
      exchangeRate = creamToken.exchangeRateStored();
      underlyingBalance = creamTokenBalance.mul(exchangeRate).div(USDC_PRECISION);
      
      
        return underlyingBalance;
    }

    function viewContractCompoundTokenBalance() external view returns (uint256) {
        return compoundToken.balanceOf(address(this));
    }

    function viewContractCreamTokenBalance() external view returns (uint256) {
        return creamToken.balanceOf(address(this));
    }
    
   function viewLastCoinPrice() external view returns(uint) {
    return lastCoinPrice;
    }

 
      function mintCircuitToken(uint amount) external {
        address sender = msg.sender;
        uint256 pricePerCoin=0;
        uint256 totalValue=0;
        uint256 amountMinted=0;
        uint256 txFee;
        uint256 mintAmount;
        uint256 compoundAcrrueInterest;
        if (contractIssuedBalance > initalPeg) {
        compoundAcrrueInterest= compoundToken.exchangeRateCurrent();
        
        totalValue = (storedUnderlyingAssetValueCompound() + storedUnderlyingAssetValueCream());
        //pricepercoin is in usdc so usdc precision is applied
        pricePerCoin = totalValue.mul(PRECISION).div(contractIssuedBalance).div(USDC_CONVERT_PRECISION);
        lastCoinPrice=pricePerCoin;
        }else{
            pricePerCoin=initalPeg;
        }
        require(underLyingAsset.transferFrom(sender, address(this), amount), 'Deposit failed');
        mintAmount = amount.mul(USDC_PRECISION).div(pricePerCoin);
        txFee = mintAmount.mul(10000).div(USDC_PRECISION);
        //the amount minted is 1% less than mintAmount
        amountMinted = (mintAmount - txFee).mul(USDC_CONVERT_PRECISION);
        //convert back in to 18 decimals

        contractIssuedBalance = contractIssuedBalance.add(amountMinted);
        _approveDepositToken(amount);
        require(compoundToken.mint((amount / 2)) == 0, "Compound mint failed");
        require(creamToken.mint((amount / 2)) == 0, "Cream mint failed");
        
        circuitYeildToken.mint(sender, amountMinted);
      }
      function burnCircuitToken(uint amount) external {
        uint256 pricePerCoinCompound=0;
        uint256 pricePerCoinCream=0;
        uint256 totalValueCompound =0;
        uint256 totalValueCream =0;
        uint256 amountHalf;
        uint256 userUnderlyingValueCompound =0;
        uint256 userUnderlyingValueCream =0;
        uint256 userTotalUnderlyingValue =0;
        address sender = msg.sender;
        uint256 compoundAcrrueInterest;
        compoundAcrrueInterest= compoundToken.exchangeRateCurrent();
        totalValueCompound = storedUnderlyingAssetValueCompound();
        pricePerCoinCompound = totalValueCompound.mul(PRECISION).div(contractIssuedBalance / 2);
        
        totalValueCream= storedUnderlyingAssetValueCream();
        pricePerCoinCream = totalValueCream.mul(PRECISION).div(contractIssuedBalance / 2);
        
        
        lastCoinPrice=((pricePerCoinCompound + pricePerCoinCream) / 2) ;
        require(circuitYeildToken.transferFrom(sender, address(this), amount), 'Yeild token exchange failed.');
        circuitYeildToken.burn(amount);
        contractIssuedBalance = contractIssuedBalance.sub(amount);
        
        amountHalf = amount.div(2);
        userUnderlyingValueCream= amountHalf.mul(pricePerCoinCream).div(PRECISION).div(USDC_CONVERT_PRECISION);
        userUnderlyingValueCompound = amountHalf.mul(pricePerCoinCompound).div(PRECISION).div(USDC_CONVERT_PRECISION);
        userTotalUnderlyingValue =(userUnderlyingValueCompound + userUnderlyingValueCream);
        
        require(compoundToken.redeemUnderlying(userUnderlyingValueCompound) == 0, "Compound redeem failed");
        require(creamToken.redeemUnderlying(userUnderlyingValueCream) == 0, "Cream redeem failed");
        require(underLyingAsset.transfer(sender,  userTotalUnderlyingValue), 'withdraw: failed');
    }
    
    function claimDevFee() external{
      uint256 compTokenBalance;
      compTokenBalance = compToken.balanceOf(address(this));
      require(compToken.transfer(admin,  compTokenBalance), 'withdraw: failed');
    }
    
    function _approveDepositToken(uint256 _minimum) internal {
        if(underLyingAsset.allowance(address(this), address(compoundToken)) < _minimum){
            underLyingAsset.approve(address(compoundToken),uint256(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff));
        }
        if(underLyingAsset.allowance(address(this), address(creamToken)) < _minimum){
            underLyingAsset.approve(address(creamToken),uint256(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff));
        }
    }


  
}
