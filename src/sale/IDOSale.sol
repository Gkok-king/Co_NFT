// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 	筹资目标（Funding Goal）：设定最低和最高筹资金额，如果未达到最低目标，资金退还给参与者；如果达到最高目标，停止筹资。
// 	定价机制（Pricing Mechanism）：设定代币的初始价格，可能是固定价格或动态价格（如荷兰拍卖）。
// 	资金接收（Fund Collection）：接收用户的投资资金，并记录各自的投资额度。
// 	代币分发（Token Distribution）：根据投资额按比例分发代币，确保公平和透明。
contract IDOSale is Ownable {
    uint256 public minFundingGoal;

    uint256 public maxFundingGoal;

    uint256 public totalFundsRaised;

    address public admin;

    mapping(address => uint256) public contributions;

    uint256 public deadline;

    ERC20 public token;

    uint256 public constant tokenTotalAmount = 1000000 * 10 ** 18;

    // 构造函数初始化筹资目标
    constructor(
        uint256 _minFundingGoal,
        uint256 _maxFundingGoal,
        uint256 _durationInMinutes,
        address _tokenAddress
    ) Ownable(_msgSender()) {
        admin = msg.sender;
        minFundingGoal = _minFundingGoal;
        maxFundingGoal = _maxFundingGoal;
        deadline = block.timestamp + _durationInMinutes;
        token = ERC20(_tokenAddress);
    }

    // 接收投资的函数  拿到的钱部分去做事儿 例如交易对
    function withdraw() public payable {
        require(block.timestamp < deadline, "too late ");
        require(
            totalFundsRaised + msg.value <= maxFundingGoal,
            "Exceeds maximum funding goal"
        );
        require(msg.value > 0.01 ether, "amount is too less");
        require(
            contributions[msg.sender] + msg.value > 0.1 ether,
            "limit amount is 0.1"
        );

        contributions[msg.sender] += msg.value;
        totalFundsRaised += msg.value;

        //todo 部分给团队
        // uint toTeam = (msg.value * 1) / 10;
        // admin.call{value: toTeam};

        emit withdrawEvent(msg.sender, msg.value);
    }

    // 检查是否达到最低筹资目标
    function checkFundingGoalReached() public view returns (bool) {
        return totalFundsRaised >= minFundingGoal;
    }

    // 退还资金给投资者（如果未达到最低筹资目标）
    function refund() public onlyFailed {
        uint256 amount = contributions[msg.sender];
        require(amount > 0, "No funds to refund");
        contributions[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
        emit refundEvent(msg.sender, amount);
    }

    // 计算投资金额对应的代币数量（此处简单假设1:1兑换）
    function getTokenAmount(address _address) public view returns (uint256) {
        return tokenTotalAmount * (contributions[_address] / totalFundsRaised);
    }

    // 提币
    function claim() public onlySuccess {
        uint256 amount = (tokenTotalAmount * contributions[msg.sender]) /
            totalFundsRaised;
        require(amount > 0, "Claim amount must be greater than zero");
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= amount, "Not enough tokens in contract");
        token.transfer(msg.sender, amount);
        contributions[msg.sender] = 0;
        emit claimEvent(msg.sender, amount);
    }

    function getSomeOne() public view returns (uint256) {
        return contributions[msg.sender];
    }

    function getTokenTotalAmount() public pure returns (uint256) {
        return tokenTotalAmount;
    }

    modifier onlySuccess() {
        require(
            block.timestamp > deadline &&
                totalFundsRaised >= minFundingGoal &&
                totalFundsRaised <= maxFundingGoal
        );
        _;
    }
    modifier onlyFailed() {
        require(
            block.timestamp > deadline && totalFundsRaised < minFundingGoal
        );
        _;
    }

    event withdrawEvent(address indexed, uint256 indexed);
    event claimEvent(address indexed, uint256 indexed);
    event refundEvent(address indexed, uint256 indexed);
}
