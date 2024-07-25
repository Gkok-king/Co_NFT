// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/EsFoolCoToken.sol";

contract StakePool {
    ERC20 public token;
    EsFoolCoToken public esToken;
    //每秒利息 线性增长
    uint256 public rate;
    //用户质押信息
    mapping(address => StakeInfo) userInfo;

    struct StakeInfo {
        uint256 tokenAmout;
        uint256 unClaimAmout;
        uint256 updateTime;
    }

    constructor(ERC20 _token, EsFoolCoToken _esToken, uint _rate) {
        token = _token;
        esToken = _esToken;
        rate = _rate;
    }

    // 质押
    function stake(uint256 _stakeAmount) public {
        require(_stakeAmount > 0, "stakeAmount error");

        uint256 newClaim = calcClaim();
        if (userInfo[msg.sender].tokenAmout == 0) {
            StakeInfo memory _stakeInfo = StakeInfo({
                tokenAmout: _stakeAmount,
                unClaimAmout: newClaim,
                updateTime: block.timestamp
            });
            userInfo[msg.sender] = _stakeInfo;
        } else {
            userInfo[msg.sender].unClaimAmout += newClaim;
        }

        token.transferFrom(msg.sender, address(this), _stakeAmount);

        emit stakeEvent(msg.sender, _stakeAmount);
    }

    //计算利息
    function calcClaim() private view returns (uint256) {
        if (userInfo[msg.sender].tokenAmout == 0) {
            return 0;
        }
        uint256 newClaim = userInfo[msg.sender].tokenAmout *
            rate *
            (block.timestamp - userInfo[msg.sender].updateTime);
        return newClaim + userInfo[msg.sender].unClaimAmout;
    }

    // 提息 如果设计成部分提，好像也没意义，越早mint，esToken越早释放，留着浪费
    function claim() public {
        require(calcClaim() > 0, "no claim");

        uint256 _esTokenAmount = calcClaim();
        userInfo[msg.sender].unClaimAmout = 0;
        userInfo[msg.sender].updateTime = block.timestamp;
        //mint  制造的比例 可以设计吗？
        esToken.mint(msg.sender, _esTokenAmount);
        emit claimEvent(msg.sender, _esTokenAmount);
    }

    // 提币
    function unStake(uint256 _unStakeAmount) public {
        require(
            userInfo[msg.sender].tokenAmout >= _unStakeAmount &&
                _unStakeAmount > 0,
            "unStakeAmount error"
        );

        //计算并清空利息
        uint256 _calim = calcClaim();
        userInfo[msg.sender].tokenAmout -= _unStakeAmount;
        userInfo[msg.sender].unClaimAmout = 0;
        userInfo[msg.sender].updateTime = block.timestamp;

        esToken.mint(msg.sender, _calim);
        token.transfer(msg.sender, _unStakeAmount);

        emit unStakeEvent(msg.sender, _unStakeAmount);
    }

    function gatClaim() public view returns (uint256) {
        return calcClaim();
    }

    event stakeEvent(address indexed user, uint256 amount);
    event unStakeEvent(address indexed user, uint256 amount);
    event claimEvent(address indexed user, uint256 amount);
}
