const { BN, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { expect } = require("chai");
const Voting = artifacts.require("Voting");

contract("Voting", function (accounts) {
    const admin = accounts[0];
    const voter1 = accounts[1];
    const voter2 = accounts[2];
    const notVoter = accounts[3];
    const proposalDescription1 = "Proposal 1";
    const proposalDescription2 = "Proposal 2";

    /**
     * @description Expect the workflow status validation by the admin.
     * 
     * @param expectedPreviousStatus 
     * @param expectedNewStatus 
     * @param voting 
     * @param callFunction 
     */
    async function expectWorkflowStatus(expectedPreviousStatus, expectedNewStatus, voting, callFunction) {
        const receipt = await callFunction({ from: admin });
        const workflowStatus = await voting.getWorkflowstatus.call({ from: admin });
        expect(workflowStatus).to.be.bignumber.equal(new BN(expectedNewStatus));
        expectEvent(
            receipt,
            "WorkflowStatusChange",
            { previousStatus: new BN(expectedPreviousStatus), newStatus: new BN(expectedNewStatus) }
        );
    }

    /**
     * Step 1: Voters registration.
     */
    context("Step 1: Voters registration", function () {
        beforeEach(async function () {
            this.voting = await Voting.new({ from: admin });
        });
        
        it("should add a voter", async function() {
            const receipt = await this.voting.addVoter(voter1, { from: admin });
            voter = await this.voting.getVoter(voter1, { from: voter1 });
            expect(voter.isRegistered).to.equal(true);
            expectEvent(receipt, "VoterRegistered", { voterAddress: voter1 });
        });

        it("should not add a voter if it is not the admin", async function() {
            await expectRevert(
                this.voting.addVoter(voter2, { from: voter1 }),
                "Ownable: caller is not the owner"
            );
        });

        it("should not add a voter if the voter is already registered", async function() {
            await this.voting.addVoter(voter1, { from: admin });
            await expectRevert(
                this.voting.addVoter(voter1, { from: admin }),
                "The voter is already registered."
            );
        });

        it("should not add a voter if the workflow status is not set at RegisteringVoters", async function() {
            await this.voting.startRegisteringProposals({ from: admin });
            await expectRevert(
                this.voting.addVoter(voter1, { from: admin }),
                "The workflow status cannot allowed you to add voters."
            );
        });
    });

    /**
     * Step 2: Proposals registration.
     */
    context("Step 2: Proposals registration", function () {
        beforeEach(async function () {
            this.voting = await Voting.new({ from: admin });
            await this.voting.addVoter(voter1, { from: admin });
            await this.voting.addVoter(voter2, { from: admin });
        });

        it("should add a proposal", async function() {
            await this.voting.startRegisteringProposals({ from: admin });
            const receipt = await this.voting.addProposal(proposalDescription1, { from: voter1 });
            const proposal = await this.voting.getProposal(0, { from: voter1 });
            expect(proposal.description).to.equal(proposalDescription1);
            expectEvent(receipt, "ProposalRegistered", { proposalId: new BN(0) });
        });

        it("should not add a proposal if it is not a voter", async function() {
            await this.voting.startRegisteringProposals({ from: admin });
            await expectRevert(
                this.voting.addProposal(proposalDescription1, { from: notVoter }),
                "You are not registered as voter."
            );
        });

        it("should not add a proposal if the workflow status is not set at RegisteringVoters", async function() {
            await this.voting.startRegisteringProposals({ from: admin });
            await this.voting.stopRegisteringProposals({ from: admin });
            await expectRevert(
                this.voting.addProposal(proposalDescription1, { from: voter1 }),
                "The workflow status cannot allowed you to request proposals."
            );
        });
    });

    /**
     * Step 3: Voting session.
     */
    context("Step 3: Voting session", function () {
        beforeEach(async function () {
            this.voting = await Voting.new({ from: admin });
            await this.voting.addVoter(voter1, { from: admin });
            await this.voting.startRegisteringProposals({ from: admin });
            await this.voting.addProposal(proposalDescription1, { from: voter1 });
            await this.voting.stopRegisteringProposals({ from: admin });
        });

        it("should set a vote", async function() {
            await this.voting.startVotingSession({ from: admin });
            const receipt = await this.voting.vote(0, { from: voter1 });
            const voter = await this.voting.getVoter(voter1, { from: voter1 });
            const proposal = await this.voting.getProposal(0, { from: voter1 });
            expect(voter.votedProposalId).to.be.equal('0');
            expect(voter.hasVoted).to.be.equal(true);
            expect(proposal.description).to.be.equal(proposalDescription1);
            expect(proposal.voteCount).to.be.equal('1');
            expectEvent(receipt, "Voted", { voter: voter1, proposalId: new BN(0) });
        });

        it("should not set a vote if it is not a voter", async function() {
            await this.voting.startVotingSession({ from: admin });
            await expectRevert(
                this.voting.vote(0, { from: notVoter }),
                "You are not registered as voter."
            );
        });

        it("should not set a vote if the workflow status is not set at VotingSessionStarted", async function() {
            await expectRevert(
                this.voting.vote(0, { from: voter1 }),
                "The workflow status not allowed you to vote."
            );
        });

        it("should not set a vote if the voter has already voted", async function() {
            await this.voting.startVotingSession({ from: admin });
            await this.voting.vote(0, { from: voter1 });
            await expectRevert(
                this.voting.vote(0, { from: voter1 }),
                "You have already voted."
            );
        });
    });

    /**
     * Step 4: Tally votes.
     */
    context("Step 4: Tally votes", function () {
        beforeEach(async function () {
            this.voting = await Voting.new({ from: admin });
            await this.voting.addVoter(voter1, { from: admin });
            await this.voting.addVoter(voter2, { from: admin });
            await this.voting.startRegisteringProposals({ from: admin });
            await this.voting.addProposal(proposalDescription1, { from: voter1 });
            await this.voting.addProposal(proposalDescription2, { from: voter2 });
            await this.voting.stopRegisteringProposals({ from: admin });
            await this.voting.startVotingSession({ from: admin });
            await this.voting.vote(1, {from: voter1});
            await this.voting.vote(1, {from: voter2});
            await this.voting.stopVotingSession({from: admin});
        });
        
        it("should tally votes and get the winner(s)", async function() {
            await this.voting.tallyVotes({ from: admin });
            const winningProposals = await this.voting.getWinners({ from: admin });
            expect(winningProposals[0].description).to.be.equal(proposalDescription2);
            expect(winningProposals[0].voteCount).to.be.equal('2');
        });
    });

    /**
     * Admin workflow validation.
     */
    context("Admin workflow validation", function () {
        beforeEach(async function () {
            this.voting = await Voting.new({ from: admin });
        });

        it("should start the proposals registering", async function() {
            expectWorkflowStatus(
                Voting.WorkflowStatus.RegisteringVoters,
                Voting.WorkflowStatus.ProposalsRegistrationStarted,
                this.voting,
                this.voting.startRegisteringProposals
            );
        });

        it("should not start the proposals registering if it is not the admin", async function() {
            await expectRevert(
                this.voting.startRegisteringProposals({ from: voter1 }),
                "Ownable: caller is not the owner"
            );
        });

        it("should not start the proposals registering if the workflow status is not set at RegisteringVoters", async function() {
            await this.voting.startRegisteringProposals({ from: admin });
            await this.voting.stopRegisteringProposals({ from: admin });
            await expectRevert(
                this.voting.startRegisteringProposals({ from: admin }),
                "The workflow status not allowed you to start registering proposals."
            );
        });

        it("should end the proposals registering", async function() {
            await this.voting.startRegisteringProposals();
            expectWorkflowStatus(
                Voting.WorkflowStatus.ProposalsRegistrationStarted,
                Voting.WorkflowStatus.ProposalsRegistrationEnded,
                this.voting,
                this.voting.stopRegisteringProposals
            );
        });

        it("should not end the proposals registering if it is not the admin", async function() {
            await expectRevert(
                this.voting.stopRegisteringProposals({ from: voter1 }),
                "Ownable: caller is not the owner"
            );
        });

        it("should not end the proposals registering if the workflow status is not set at ProposalsRegistrationStarted", async function() {
            await expectRevert(
                this.voting.stopRegisteringProposals(),
                "The workflow status not allowed you to stop registering proposals."
            );
        });
    
        it("should start the voting session", async function() {
            await this.voting.startRegisteringProposals();
            await this.voting.stopRegisteringProposals();

            expectWorkflowStatus(
                Voting.WorkflowStatus.ProposalsRegistrationEnded,
                Voting.WorkflowStatus.VotingSessionStarted,
                this.voting,
                this.voting.startVotingSession
            );
        });

        it("should not start the voting session if it is not the admin", async function() {
            await this.voting.startRegisteringProposals();
            await this.voting.stopRegisteringProposals();
            await expectRevert(
                this.voting.startVotingSession({ from: voter1 }),
                "Ownable: caller is not the owner"
            );
        });

        it("should not start the voting session if the workflow status is not set at ProposalsRegistrationEnded", async function() {
            await expectRevert(
                this.voting.startVotingSession(),
                "The workflow status not allowed you to start the voting session."
            );
        });

        it("should end the voting session", async function() {
            await this.voting.startRegisteringProposals();
            await this.voting.stopRegisteringProposals();
            await this.voting.startVotingSession();
            expectWorkflowStatus(
                Voting.WorkflowStatus.VotingSessionStarted,
                Voting.WorkflowStatus.VotingSessionEnded,
                this.voting,
                this.voting.stopVotingSession
            );
        });

        it("should not end the voting session if it is not the admin", async function() {
            await expectRevert(
                this.voting.stopVotingSession({ from: voter1 }),
                "Ownable: caller is not the owner"
            );
        });

        it("should not end the voting session if the workflow status is not set at VotingSessionStarted", async function() {
            await expectRevert(
                this.voting.stopVotingSession(),
                "The workflow status not allowed you to stop the voting session."
            );
        });

        it("should tally votes", async function() {
            await this.voting.startRegisteringProposals();
            await this.voting.stopRegisteringProposals();
            await this.voting.startVotingSession();
            await this.voting.stopVotingSession({from: admin});

            expectWorkflowStatus(
                Voting.WorkflowStatus.VotingSessionEnded,
                Voting.WorkflowStatus.VotesTallied,
                this.voting,
                this.voting.tallyVotes
            );
        });

        it("should not tally votes if it is not the admin", async function() {
            await expectRevert(
                this.voting.tallyVotes({ from: voter1 }),
                "Ownable: caller is not the owner"
            );
        });

        it("should not tally votes if the workflow status is not set at VotingSessionEnded", async function() {
            await expectRevert(
                this.voting.tallyVotes(),
                "The workflow status not allowed you to tally votes."
            );
        });
    });
});
