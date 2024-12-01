pragma solidity ^0.8.0;

contract JanusCommodities {
    struct Derivative {
        string name;
        uint256 price;
        uint256 expiry;
        uint256 supply;
    }

    mapping(uint256 => Derivative) public derivatives;
    mapping(address => mapping(uint256 => uint256)) public balances;

    uint256 public nextDerivativeId;
    address public admin;

    event DerivativePurchased(
        address indexed buyer,
        uint256 indexed derivativeId,
        uint256 amount
    );
    event DerivativeSold(
        address indexed seller,
        uint256 indexed derivativeId,
        uint256 amount
    );

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function createDerivative(
        string memory name,
        uint256 price,
        uint256 expiry,
        uint256 supply
    ) external onlyAdmin {
        derivatives[nextDerivativeId] = Derivative(name, price, expiry, supply);
        nextDerivativeId++;
    }

    function purchaseDerivative(uint256 derivativeId, uint256 amount)
        external
        payable
    {
        Derivative storage derivative = derivatives[derivativeId];
        require(block.timestamp < derivative.expiry, "Derivative expired");
        require(
            msg.value == derivative.price * amount,
            "Incorrect payment amount"
        );
        require(derivative.supply >= amount, "Not enough supply");

        derivative.supply -= amount;
        balances[msg.sender][derivativeId] += amount;

        emit DerivativePurchased(msg.sender, derivativeId, amount);
    }

    function sellDerivative(uint256 derivativeId, uint256 amount) external {
        Derivative storage derivative = derivatives[derivativeId];
        require(balances[msg.sender][derivativeId] >= amount, "Insufficient balance");
        require(block.timestamp < derivative.expiry, "Derivative expired");

        uint256 refund = derivative.price * amount;
        balances[msg.sender][derivativeId] -= amount;
        derivative.supply += amount;

        payable(msg.sender).transfer(refund);

        emit DerivativeSold(msg.sender, derivativeId, amount);
    }

    function getBalance(uint256 derivativeId) external view returns (uint256) {
        return balances[msg.sender][derivativeId];
    }

    function withdrawFunds() external onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }

    receive() external payable {}
}
