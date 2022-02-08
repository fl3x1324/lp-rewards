// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./LPBadge.sol";

contract LPRewards is Ownable {
    mapping(address => uint256) private claimedBadgeTiers;
    mapping(address => uint256) private stakerAmounts;
    mapping(address => DepositReward) private stakerRewards;
    uint256 private baseScore;
    uint256 private levelMult;
    uint256 private scoreMult;
    LPBadge private lpBadge;

    constructor(LPBadge _lpBadge) {
        lpBadge = _lpBadge;
        baseScore = 1_000_000;
        levelMult = 5;
        scoreMult = 1;
    }

    function withdraw() public {}

    function deposit() public payable {
        address sender = address(msg.sender);
        DepositReward memory reward = stakerRewards[sender];
        uint256 depositPeriod = _getDepositPeriod(
            reward.timestamp,
            block.timestamp
        );
        reward.accumScore += depositPeriod * scoreMult * reward.lastDeposit;
        reward.timestamp = block.timestamp;
        reward.lastDeposit = msg.value;
        stakerRewards[sender] = reward;
        stakerAmounts[sender] += msg.value;
    }

    function claimBadge() public {
        uint256 badgeTier = getBadgeTier();
        require(badgeTier > 0, "You don't have a reward tier yet.");
        uint256 tokenId = lpBadge.safeMint(
            address(msg.sender),
            string(
                abi.encodePacked(
                    "tier-",
                    Strings.toString(badgeTier),
                    "-metadata.json"
                )
            )
        );
        DepositReward memory reward = stakerRewards[address(msg.sender)];
        if (reward.lastTokenId > 0) {
            lpBadge.burnToken(reward.lastTokenId);
        }
        reward.lastTokenId = tokenId;
        stakerRewards[address(msg.sender)] = reward;
    }

    function getBadgeTier() public view returns (uint256) {
        DepositReward memory reward = stakerRewards[msg.sender];
        uint256 depositPeriod = _getDepositPeriod(
            reward.timestamp,
            block.timestamp
        );
        uint256 score = (reward.accumScore +
            depositPeriod *
            reward.lastDeposit) * scoreMult;
        return _calculateTier(0, score / baseScore);
    }

    function setScoreMult(uint256 _scoreMult) public onlyOwner {
        require(_scoreMult > 0, "Score multiplier can't be less than 1");
        scoreMult = _scoreMult;
    }

    function setBaseTierScore(uint256 _baseScore) public onlyOwner {
        baseScore = _baseScore;
    }

    function setLevelMult(uint256 _levelMult) public onlyOwner {
        levelMult = _levelMult;
    }

    function _getDepositPeriod(
        uint256 _depositTimestamp,
        uint256 _currenTtimestamp
    ) private pure returns (uint256) {
        return
            _depositTimestamp > 0 ? _currenTtimestamp - _depositTimestamp : 0;
    }

    /**
        Next tier is 5X the score needed for the previous one
        Tier 1 = 1_000_000
        Tier 2 = 5_000_000
        Tier 3 = 25_000_000
     */
    function _calculateTier(uint256 _tier, uint256 _baseScoreMult)
        private
        view
        returns (uint256)
    {
        if (_baseScoreMult < 1) {
            return _tier;
        }
        return _calculateTier(_tier + 1, _baseScoreMult / levelMult);
    }

    struct DepositReward {
        uint256 timestamp;
        uint256 accumScore;
        uint256 lastDeposit;
        uint256 lastTokenId;
    }
}
