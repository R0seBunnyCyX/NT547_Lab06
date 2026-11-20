// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// NT547 - Lab 06 - Hop dong rieng cua MSSV 24520943. KHONG deploy len mainnet.

interface IERC20Like {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TipJar_0943 {
    address public owner;
    address public module;
    mapping(address => uint256) public stakes;
    uint256 public nextRelease;
    mapping(bytes32 => bool) public redeemed;

    event Deposited(address indexed who, uint256 amount);
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function contribute() external payable {
        stakes[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function ownerWithdraw(uint256 amount) external onlyOwner {
        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "withdraw failed");
    }

    function noFunds() external view returns (bool) {
        // Accepted: view-only UI helper, never used for access control or fund flow.
        // slither-disable-next-line incorrect-equality
        return address(this).balance == 0;
    }

    function drip() external onlyOwner {
        require(block.timestamp >= nextRelease, "locked");
        nextRelease = block.timestamp + 1 days;
        (bool ok, ) = payable(owner).call{value: address(this).balance / 10}("");
        require(ok, "release failed");
    }

    function changeOwner(address newOwner) external {
        require(msg.sender == owner, "not owner");
        require(newOwner != address(0), "zero");
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    function setModule(address newModule) external onlyOwner {
        require(newModule.code.length > 0, "not a contract");
        module = newModule;
    }

    function plugin(bytes calldata data) external onlyOwner {
        require(module != address(0), "no module");
        // Accepted: caller is msg.sender-checked owner and destination is the owner-configured
        // module (no caller-supplied target). Residual risk = trust in owner's module choice.
        // slither-disable-next-line controlled-delegatecall
        (bool ok, ) = module.delegatecall(data);
        require(ok, "delegatecall failed");
    }

    function redeemCode(string calldata campaign, string calldata code) external {
        bytes32 id = keccak256(abi.encode(campaign, code));
        require(!redeemed[id], "used");
        redeemed[id] = true;
        stakes[msg.sender] += 1;
    }

    function sweep(address payable to) external onlyOwner {
        require(to != address(0), "zero");
        (bool ok, ) = to.call{value: address(this).balance}("");
        require(ok, "sweep failed");
    }
}
