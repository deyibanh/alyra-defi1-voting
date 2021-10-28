// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Voting
 *
 * @dev A voting system.
 */
contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    uint private incrementalProposalId;
    uint private winningProposalId;
    address[] private whitelist;
    mapping (address => Voter) private voters;
    mapping (address => Proposal) private proposals;
    Voting.WorkflowStatus private workflowStatus;

    /**
     * @dev Constructor.
     */
    constructor() Ownable() {
        initWhitelist();
        workflowStatus = WorkflowStatus.RegisteringVoters;
    }

    /**
     * @dev Initialize the whitelist with specific addresses.
     */
    function initWhitelist() private {
        whitelist.push(0x039821D4a1fAE62807499d4b89F5bC8C4A929e6c);
        whitelist.push(0xa6a0E2b63F74f6F16bf6DF09dA021ac8D4E32fBc);
        whitelist.push(0xf5A08f0aEf033c1e0466bF85661d51973DB97aEd);
        whitelist.push(0x79C0ece05791d98Efe8383F973091443A32572b4);
        whitelist.push(0x3e32fB744706830706ba69F3bfDbf5dDC299f442);

        for (uint i = 0; i < whitelist.length; i++) {
            addVoter(whitelist[i]);
        }
    }

    /**
     * @dev Add a voter address into the whitelist.
     *
     * @param _voterAddress The voter address.
     */
    function addVoter(address _voterAddress) public onlyOwner {
        Voter memory voter;
        voter.isRegistered = false;
        voter.hasVoted = false;
        voter.votedProposalId = incrementalProposalId;
        voters[_voterAddress] = voter;
        incrementalProposalId++;
        emit VoterRegistered(_voterAddress);
    }

    /**
     * @dev Get a voter information.
     *
     * @return Voter.
     */
    function getVoter(address _voterAddress) public view returns (Voter memory) {
        return voters[_voterAddress];
    }

    /**
     * @dev Get a proposal information.
     *
     * @return Proposal.
     */
    function getProposal(address _voterAddress) public view returns (Proposal memory) {
        return proposals[_voterAddress];
    }

    /**
     * @dev Get a voter information.
     *
     * @return Voter The voter information.
     */
    function getWorkflowstatus() public view returns (Voting.WorkflowStatus) {
        return workflowStatus;
    }

    /**
     * @dev Start to register voters.
     */
    function startRegisteringVoters() public onlyOwner {
        for (uint i = 0; i < whitelist.length; i++) {
            address voterAddress = whitelist[i];
            voters[voterAddress].isRegistered = true;
        }

        workflowStatus = WorkflowStatus.RegisteringVoters;
    }

    /**
     * @dev Start to register proposals.
     */
    function startRegisteringProposals() public onlyOwner {
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /**
     * @dev Request a proposal with a description.
     *
     * @param _description The description of the proposal.
     */
    function requestProposal(string memory _description) public {
        Proposal memory proposal;
        proposal.description = _description;
    }

    /**
     * @dev Stop registering proposals.
     */
    function stopRegisteringProposals() public onlyOwner {
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /**
     * @dev Start the voting session.
     */
    function startVotingSession() public onlyOwner {
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /**
     * @dev Vote.
     */
    function vote() public {
    }

    /**
     * @dev Stop the voting session.
     */
    function stopVotingSession() public onlyOwner {
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /**
     * @dev Tally all votes.
     */
    function tallyVotes() public onlyOwner {
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }

    /**
     * @dev Get the winning proposal id.
     *
     * @return uint.
     */
    function getWinningProposalId() public view returns (uint) {
        return winningProposalId;
    }

    /**
     * @dev Get the winning proposal detail.
     *
     * @return uint.
     */
    function getWinner() public view returns (uint) {
        return winningProposalId;
    }
}
