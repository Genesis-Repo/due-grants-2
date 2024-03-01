// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GrantsTracker is Ownable {
    
    struct Grant {
        address recipient;
        uint256 amount;
        uint256 releaseTime;
        bool released;
    }
    
    mapping(uint256 => Grant) public grants;
    uint256 public grantsCount;
    IERC20 public token;
    bool public emergencyStop; // Emergency stop flag

    event GrantCreated(uint256 id, address recipient, uint256 amount, uint256 releaseTime);
    event GrantReleased(uint256 id);
    
    constructor(IERC20 _token) {
        token = _token;
        emergencyStop = false; // Initialize emergency stop as false
    }

    function createGrant(address _recipient, uint256 _amount, uint256 _releaseTime) external onlyOwner {
        require(!emergencyStop, "Operations are paused due to emergency stop");
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Invalid grant amount");
        require(_releaseTime > block.timestamp, "Release time must be in the future");
        
        grants[grantsCount] = Grant(_recipient, _amount, _releaseTime, false);
        
        emit GrantCreated(grantsCount, _recipient, _amount, _releaseTime);

        token.transferFrom(msg.sender, address(this), _amount);

        grantsCount++;
    }

    function releaseGrant(uint256 _id) external {
        require(!emergencyStop, "Operations are paused due to emergency stop");
        require(_id < grantsCount, "Grant does not exist");
        Grant storage grant = grants[_id];
        require(grant.releaseTime <= block.timestamp, "Grant release time has not been reached");
        require(!grant.released, "Grant already released");
        
        grant.released = true;
        token.transfer(grant.recipient, grant.amount);
        
        emit GrantReleased(_id);
    }

    function toggleEmergencyStop() external onlyOwner {
        emergencyStop = !emergencyStop;
    }
    
}