// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

// esToken 用来换取原token
contract EsFoolCoToken is
    ERC20("EsFoolCo", "EFC"),
    ERC20Permit("EsGongToken"),
    Ownable
{
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    address public takePool;
    ERC20 public token;
    // 兑换比例
    uint256 public exchangeRate;
    // 锁定 设计成这样，是考虑多个用户问题
    mapping(address => LockInfo[]) lockArray;
    uint256 public lockTimeLength;
    struct LockInfo {
        address user;
        uint256 amount;
        uint256 lockTime;
    }

    constructor(ERC20 _token) Ownable(_msgSender()) {
        token = _token;
        token.approve(address(this), token.totalSupply());
    }

    function setExchangeRate(uint256 _exchangeRate) external onlyOwner {
        exchangeRate = _exchangeRate;
    }

    function mint(address _to, uint256 _amount) public onlyTakePool {
        _mint(_to, _amount);
        // 锁定token
        LockInfo memory lockInfo = LockInfo({
            user: msg.sender,
            amount: _amount,
            lockTime: block.timestamp
        });
        lockArray[_to].push(lockInfo);
        emit TokensMint(_to, _amount);
    }

    function calcUnLockToken() private view returns (uint256, uint256) {
        if (lockArray[msg.sender][0].user == address(0)) {
            return (0, 0);
        }
        uint256 unlockAmount = 0;
        uint256 lockAmount = 0;
        for (uint i = 0; i < lockArray[msg.sender].length; i++) {
            if (
                lockArray[msg.sender][i].lockTime + lockTimeLength >
                block.timestamp
            ) {
                unlockAmount += lockArray[msg.sender][i].amount;
            } else {
                //根据时间 算出锁定的token
                lockAmount +=
                    (lockArray[msg.sender][i].amount *
                        (block.timestamp - lockArray[msg.sender][i].lockTime)) /
                    lockTimeLength;
                //剩下是解锁的
                unlockAmount += lockArray[msg.sender][i].amount - lockAmount;
            }
        }
        return (unlockAmount, lockAmount);
    }

    function swapTokens(uint256 _esTokenAmount) external {
        require(_esTokenAmount > 0, "Amount must be greater than zero");

        //计算信息
        (uint unlockAmount, uint256 lockAmount) = calcUnLockToken();

        //清除锁定信息
        cleanLockInfo(_esTokenAmount);

        // 转移目标 token 给用户
        uint256 targetTokenAmount = _esTokenAmount * unlockAmount;
        token.transfer(msg.sender, targetTokenAmount);

        // 烧毁
        _burn(msg.sender, lockAmount);
    }

    // 感觉成本太高了
    function cleanLockInfo(uint256 _esTokenAmount) public {
        uint256 _amount = _esTokenAmount;
        uint256 index = 0;
        for (uint i = 0; i < lockArray[msg.sender].length; i++) {
            if (_amount - lockArray[msg.sender][i].amount > 0) {
                index += 1;
                _amount -= lockArray[msg.sender][i].amount;
            } else if (_amount - lockArray[msg.sender][i].amount == 0) {
                index += 1;
            } else {
                lockArray[msg.sender][i].amount -= _amount;
            }
        }
        // 调整数组长度，
        uint j = 0;
        for (uint i = index; i <= lockArray[msg.sender].length; i++) {
            lockArray[msg.sender][j] = lockArray[msg.sender][i];
            j++;
        }
    }

    // permit
    function _permit(
        address _owner,
        address spender,
        uint256 value,
        bytes memory signature
    ) public returns (bool) {
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 structHash = keccak256(
            abi.encode(
                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)",
                _owner,
                spender,
                value,
                this.nonces,
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        require(signer == _owner, "Permit: invalid signature");

        _approve(_owner, spender, value);

        return true;
    }

    function setTakePool(address _address) public onlyOwner {
        takePool = _address;
    }

    modifier onlyTakePool() {
        require(msg.sender == takePool);
        _;
    }
    event TokensMint(address _address, uint amount);
    event TokensBurned(address send, uint amount);
}
