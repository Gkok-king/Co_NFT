// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// 编写一个 Bank 存款合约，实现功能：

// 可以通过 Metamask 等钱包直接给 Bank 合约地址存款
// 在 Bank 合约里记录了每个地址的存款金额
// 用可迭代的链表保存存款金额的前 10 名用户
// 请提交你的 github 仓库地址。

contract MyBank2 {
    // admin 用户
    address private admin;

    // 存款记录map
    mapping(address => uint) depositMap;

    // 存款前十记录的链表
    mapping(address => address) public deposits;
    address public HEAD = address(1);

    uint256 public maxSize;
    uint256 public currentSize;

    receive() external payable {
        deposit();
    }

    fallback() external payable {}

    // 生成管理员
    constructor() {
        admin = msg.sender;
        deposits[HEAD] = address(0);
        maxSize = 10;
        currentSize = 0;
    }

    // 修饰符：仅允许管理员调用
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert PermissionError(msg.sender);
        }
        _;
    }

    // 提款函数，仅管理员可调用
    function withdraw(uint value) public onlyAdmin {
        // 取和存的钱不能为0
        if (value == 0 || address(this).balance == 0) {
            revert balanceZero(msg.sender);
        }

        // 向管理员地址发送余额
        payable(admin).transfer(value);
    }

    // 存款函数，允许用户存款并记录存款信息
    function deposit() public payable {
        if (msg.value == 0) {
            revert balanceZero(msg.sender);
        }
        //记录具体地址金额
        depositMap[msg.sender] += msg.value;

        // 成功事件
        emit depositSuccess(msg.sender, msg.value);
    }

    // 链表添加
    function add(address pre, address next) public onlyAdmin {
        require(deposits[pre] == address(0));
        require(deposits[next] != address(0));
        deposits[pre] = next;
        deposits[next] = address(0);
        currentSize++;
    }

    // 链表删除
    function del(address pre, address cur) public onlyAdmin {
        require(cur != address(0));
        require(deposits[pre] == cur);
        deposits[pre] = deposits[cur];
        currentSize--;
    }

    // 链表更新
    function update(
        address pre,
        address cur,
        address newAddr
    ) public onlyAdmin {
        require(cur != address(0));
        require(deposits[pre] == cur);
        deposits[pre] = newAddr;
        deposits[newAddr] = deposits[cur];
    }

    // 查看前几名用户的账户
    function getTop(uint256 k) public view returns (address[] memory) {
        require(currentSize > 0);
        require(k <= maxSize);
        address[] memory list = new address[](k);
        address currentAddress = HEAD;
        for (uint256 i = 0; i < k; ++i) {
            list[i] = currentAddress;
            currentAddress = deposits[currentAddress];
        }
        return list;
    }

    // 事件
    event depositSuccess(address indexed, uint256 indexed value);
    // 定义错误
    error IndexOutOfBounds(uint256 index, uint256 length);
    error PermissionError(address Address);
    error balanceZero(address Address);
}
