// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingContract {
    struct Choice {
        string name;
        uint256 voteCount;
    }

    struct Voter {
        bool hasVoted;
        uint256 votedChoice;
    }

    address public owner;
    uint256 public startTime;
    uint256 public endTime;
    bool public votingClosed;

    Choice[] public choices;
    mapping(address => Voter) public voters;
    mapping(uint256 => address) public choiceToVoter;

    event VoteCasted(address indexed voter, uint256 choiceIndex);

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only contract owner can perform this action"
        );
        _;
    }

    modifier onlyDuringVotingPeriod() {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Voting period is not active"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
        votingClosed = false;
    }

    function addChoice(
        string memory _name
    ) public onlyOwner onlyDuringVotingPeriod {
        require(!votingClosed, "Voting period is closed");
        choices.push(Choice(_name, 0));
    }

    function startVoting(
        uint256 _startTime,
        uint256 _endTime
    ) public onlyOwner {
        require(!votingClosed, "Voting period is closed");
        require(_endTime > _startTime, "Invalid voting period");

        startTime = _startTime;
        endTime = _endTime;
    }

    function castVote(uint256 _choiceIndex) public onlyDuringVotingPeriod {
        require(!votingClosed, "Voting period is closed");
        require(_choiceIndex < choices.length, "Invalid choice index");
        require(!voters[msg.sender].hasVoted, "Already voted");

        choices[_choiceIndex].voteCount++;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedChoice = _choiceIndex;
        choiceToVoter[_choiceIndex] = msg.sender;

        emit VoteCasted(msg.sender, _choiceIndex);
    }

    function getChoiceCount() public view returns (uint256) {
        return choices.length;
    }

    function getVoteCount(uint256 _choiceIndex) public view returns (uint256) {
        require(_choiceIndex < choices.length, "Invalid choice index");
        return choices[_choiceIndex].voteCount;
    }

    function closeVoting() public onlyOwner {
        require(!votingClosed, "Voting period is already closed");
        votingClosed = true;
    }

    function getRandomVoterFromHighestVotedChoice()
        public
        view
        onlyOwner
        returns (address)
    {
        require(votingClosed, "Voting period is still active");

        uint256 highestVoteCount = 0;
        uint256 highestVoteIndex = 0;
        uint256 count = choices.length;

        for (uint256 i = 0; i < count; i++) {
            if (choices[i].voteCount > highestVoteCount) {
                highestVoteCount = choices[i].voteCount;
                highestVoteIndex = i;
            } else if (choices[i].voteCount == highestVoteCount) {
                if (
                    uint256(
                        keccak256(abi.encodePacked(blockhash(block.number - 1)))
                    ) %
                        2 ==
                    0
                ) {
                    highestVoteIndex = i;
                }
            }
        }

        return choiceToVoter[highestVoteIndex];
    }
}
