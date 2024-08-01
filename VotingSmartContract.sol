// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vote {
    address electionCommission;
    address public winner;
    
    enum Gender { Male, Female, Other}
    
    struct Voter{
        string name;
        uint age;
        uint voterId;
        Gender gender;
        uint voteCandidateId;
        address voterAddress;
    }

    struct Candidate{
        string name;
        string party;
        uint age;
        Gender gender;
        uint candidateId;
        address candidateAddress;
        uint votes;

    }

    enum VotingStatus { NotStarted, InProgress, Ended}

    uint nextVoterId = 1;
    uint nextCandidateId = 1;
    uint startTime;
    uint endTime;

    mapping(uint => Voter) voterDetails;
    mapping(uint => Candidate) candidateDetails;
    bool stopVoting;
    IERC20 public gldToken;
    event NewCandidateRegistered(string name, string party, uint age, Gender gender, uint candidateId);
    event NewVoterRegistered(string name, uint age, Gender gender, uint voterId);
    event VoteCasted(uint voterId, uint candidateId);
    event VotingPeriodSet(uint startTime, uint endTime);
    event VotingStatusUpdated(VotingStatus status);
    event ElectionResultAnnounced(address winner);

    constructor(address _gldToken) {
        gldToken=IERC20(_gldToken);
        electionCommission = msg.sender;
    }

    modifier isVotingOver() {
        require(block.timestamp > endTime || stopVoting == true, "Voting is not over");
        _;
    }

    modifier onlyCommisioner(){
        require(electionCommission == msg.sender, "not from election Commision");
        _;
    }


    function candidateRegister(
        string calldata _name,
        string calldata _party,
        uint256 _age,
        Gender _gender
    )  external {
        require(_age>=18,"Age is under 18");
        require(candidateVerification(msg.sender),"you have already registered");
        require(nextCandidateId < 3, "Candidate registration full");

        candidateDetails[nextCandidateId] = Candidate( _name, _party, _age, _gender, nextCandidateId, msg.sender,
        0
        );
        emit NewCandidateRegistered(_name, _party, _age, _gender, nextCandidateId);
        nextCandidateId++;

    }

    function candidateVerification(address _person) internal view returns (bool) {
        for(uint candidateId= 1; candidateId < nextCandidateId; candidateId++){
            if(candidateDetails[candidateId].candidateAddress== _person){
                return false;
            }
        }
        return true;

    }

    function candidateList() public view returns (Candidate[] memory) {
        Candidate[] memory candidateArr = new Candidate[](nextCandidateId-1);
        for(uint i=1;i<nextCandidateId; i++){
            candidateArr[i-1] = candidateDetails[i];
            }
            return candidateArr;

    }

    function voterRegister(
        string calldata _name, 
        uint256 _age, 
        Gender _gender
        ) external{
        require(voterVerification(msg.sender),"Voter Already Registered");
        require(_age >= 18, "You are not eligible");

        voterDetails[nextVoterId] = Voter(_name,_age, nextVoterId, _gender, 0, msg.sender);
        emit NewVoterRegistered(_name, _age, _gender, nextVoterId);
        nextVoterId++;
    }

    function voterVerification(address _person) internal view returns (bool) {
        for(uint256 voterId = 1; voterId < nextVoterId; voterId++) {
            if(voterDetails[voterId].voterAddress == _person){
                return false;
            }
        }

        return true;
    }

    function voterList() public view returns (Voter[] memory) {
        Voter[] memory voterArr = new Voter[](nextVoterId - 1);
        for(uint256 i = 1; i < nextVoterId; i++){
            voterArr[i-1] = voterDetails[i];
        }

        return voterArr;

    }

    function vote(uint _voterId, uint _candidateId) external {
        require(gldToken.balanceOf(msg.sender)>0,"Not enough tokens");
        require(voterDetails[_voterId].voterAddress == msg.sender,"Already voted");
        require(_candidateId>0 && _candidateId<3,"You are not a voter");
        require(startTime !=0,"Voting not startted");
        require(nextCandidateId == 3,"candidate registration not done yet");
        require(voterDetails[_voterId].voteCandidateId==0,"Voter has already voted");

        ////gldToken.safeTransferfrom(msg.sender, address(this), 1);
        voterDetails[_voterId].voteCandidateId = _candidateId;
        candidateDetails[_candidateId].votes++;
        ////emit VoteCasted(_voterId, _candidateId);
    }

    function voteTime(uint _startTime, uint duration) external onlyCommisioner() {
        startTime = _startTime;
        endTime = _startTime + duration;

        emit VotingPeriodSet(startTime, endTime);
    }

    function votingStatus() public view returns (string memory){
        if(startTime == 0){
            return "Voting has not started";
        } else if(endTime>block.timestamp && stopVoting!=true) {
            return "Voting In Progress";
        } else {
            return "Voting Ended";
        }
    }

    function result() external onlyCommisioner() {
        require(nextCandidateId > 1, "No candidates registered");
        uint max = 0;
        for (uint i = 1; i<nextCandidateId; i++){
            if(candidateDetails[i].votes > max){
                max = candidateDetails[i].votes;
                winner = candidateDetails[i].candidateAddress;
            }
        }
    }

    function emergency() public onlyCommisioner() {
        stopVoting = true;
    }

}