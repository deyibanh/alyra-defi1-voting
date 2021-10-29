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

    uint private winningProposalId;
    WorkflowStatus private workflowStatus;
    Proposal[] private proposals;
    mapping (address => Voter) private voters;

    /**
     * @dev Constructor.
     */
    constructor() Ownable() {
        workflowStatus = WorkflowStatus.RegisteringVoters;
        addVoter(msg.sender);
    }

    /**
     * @dev Check if the sender is registered in the voters list.
     */
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You are not registered as voter.");
        _;
    }

    /**
     * @dev Compare two string and return a boolean.
     *
     * @param str1 The first string.
     * @param str2 The second string.
     *
     * @return bool Returns false if there is a difference, otherwise returns true.
     */
    function strcmp(string memory str1, string memory str2) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((str1))) == keccak256(abi.encodePacked((str2))));
    }

    /**
     * @dev Initialize the whitelist with specific addresses for demo.
     */
    function initWhitelistForDemo() public onlyOwner {
        addVoter(0xa6a0E2b63F74f6F16bf6DF09dA021ac8D4E32fBc);
        addVoter(0xf5A08f0aEf033c1e0466bF85661d51973DB97aEd);
        addVoter(0x79C0ece05791d98Efe8383F973091443A32572b4);
        addVoter(0x3e32fB744706830706ba69F3bfDbf5dDC299f442);
    }

    /**
     * @dev Get the workflow status.
     *
     * @return Workflowstatus The workflowStatus.
     */
    function getWorkflowstatus() public view returns (WorkflowStatus) {
        return workflowStatus;
    }

    /**
     * @dev Add a voter address into the voters list.
     *
     * @param _voterAddress The voter address.
     */
    function addVoter(address _voterAddress) public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'The workflow status cannot allowed you to add voters.');
        require(!voters[_voterAddress].isRegistered, 'The voter is already registered.');

        voters[_voterAddress].isRegistered = true;

        emit VoterRegistered(_voterAddress);
    }

    /**
     * @dev Remove a voter address from the voters list.
     *
     * @param _voterAddress The voter address.
     */
    function removeVoter(address _voterAddress) public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'The workflow status cannot allowed you to remove voters.');
        require(voters[_voterAddress].isRegistered, 'The voter is already not registered.');

        voters[_voterAddress].isRegistered = false;

        emit VoterRegistered(_voterAddress);
    }

    /**
     * @dev Get a voter information.
     *
     * @param _voterAddress The voter address.
     *
     * @return Voter The voter.
     */
    function getVoter(address _voterAddress) public onlyVoters view returns (Voter memory) {
        return voters[_voterAddress];
    }

    /**
     * @dev Request a proposal with a description.
     *
     * @param _description The description of the proposal.
     */
    function requestProposal(string memory _description) public onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'The workflow status cannot allowed you to request proposals.');
        require(!strcmp(_description, ''), 'Please enter a valid description.');

        Proposal memory proposal;
        proposal.description = _description;
        proposals.push(proposal);

        emit ProposalRegistered(proposals.length - 1);
    }

    /**
     * @dev Get all proposal.
     *
     * @return Proposal[] The proposal list.
     */
    function getProposals() public view onlyVoters returns (Proposal[] memory)  {
        return proposals;
    }

    /**
     * @dev Get a proposal information with an the proposal id.
     *
     * @param _proposalId The proposal id.
     *
     * @return Proposal The proposal information.
     */
    function getProposal(uint _proposalId) public view onlyVoters returns (Proposal memory) {
        require(_proposalId < proposals.length, 'Proposal not found. Please enter a valid id.');

        return proposals[_proposalId];
    }

    /**
     * @dev Start to register proposals.
     */
    function startRegisteringProposals() public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'The workflow status cannot allowed you to start registering proposals.');

        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;

        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /**
     * @dev Stop registering proposals.
     */
    function stopRegisteringProposals() public onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'The workflow status cannot allowed you to stop registering proposals.');
        
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;

        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /**
     * @dev Start the voting session.
     */
    function startVotingSession() public onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'The workflow status cannot allowed you to start the voting session.');
        
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /**
     * @dev Vote to a proposal.
     *
     * @param _proposalId The proposal id.
     */
    function vote(uint _proposalId) public onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'The workflow status cannot allowed you to vote.');
        require(_proposalId < proposals.length, 'Proposal not found. Please enter a valid id.');
        require(!voters[msg.sender].hasVoted, 'You have already voted.');

        Voter storage voter = voters[msg.sender];
        voter.votedProposalId = _proposalId;
        voter.hasVoted = true;
        proposals[_proposalId].voteCount++;

        emit Voted(msg.sender, _proposalId);
    }

    /**
     * @dev Stop the voting session.
     */
    function stopVotingSession() public onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'The workflow status cannot allowed you to stop the voting session.');
        
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /**
     * @dev Tally all votes.
     */
    function tallyVotes() public onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, 'The workflow status cannot allowed you to tally votes.');

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[winningProposalId].voteCount < proposals[i].voteCount) {
                winningProposalId = i;
            }
        }

        workflowStatus = WorkflowStatus.VotesTallied;

        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }

    /**
     * @dev Get the winning proposal id.
     *
     * @return uint The winning proposal id..
     */
    function getWinningProposalId() public view returns (uint) {
        require(workflowStatus == WorkflowStatus.VotesTallied, 'The workflow status cannot allowed you to see the winner proposal.');

        return winningProposalId;
    }

    /**
     * @dev Get the winning proposal detail.
     *
     * @return Proposal The winning proposal.
     */
    function getWinner() public view returns (Proposal memory) {
        require(workflowStatus == WorkflowStatus.VotesTallied, 'The workflow status cannot allowed you to see the winner proposal.');

        return proposals[winningProposalId];
    }
}
