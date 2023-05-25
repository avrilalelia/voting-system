import React, { useState, useEffect } from "react";
import getWeb3 from "./web3";
import contractABI from "./votingContractABI";
import TruffleContract from "truffle-contract";

const App = () => {
  const [web3, setWeb3] = useState(null);
  const [votingContract, setVotingContract] = useState(null);
  const [choices, setChoices] = useState([]);
  const [votedChoice, setVotedChoice] = useState(null);
  const [loading, setLoading] = useState(false);
  const [voteCount, setVoteCount] = useState(0);
  const [randomVoter, setRandomVoter] = useState(null);

  useEffect(() => {
    const init = async () => {
      try {
        const web3Instance = await getWeb3();
        const contract = TruffleContract(contractABI);
        contract.setProvider(web3Instance.currentProvider);
        const instance = await contract.deployed();
        setWeb3(web3Instance);
        setVotingContract(instance);
        await getChoices();
        await getVoteCount();
      } catch (error) {
        console.error("Error initializing web3 and smart contract", error);
      }
    };

    init();
  }, []);

  const getChoices = async () => {
    const choiceCount = await votingContract.getChoiceCount();
    const choices = [];

    for (let i = 0; i < choiceCount; i++) {
      const choice = await votingContract.choices(i);
      choices.push(choice);
    }

    setChoices(choices);
  };

  const getVoteCount = async () => {
    const count = await votingContract.getVoteCount();
    setVoteCount(count);
  };

  const handleVote = async (choiceIndex) => {
    setLoading(true);

    try {
      await votingContract.castVote(choiceIndex);
      setVotedChoice(choices[choiceIndex]);
      await getVoteCount();
    } catch (error) {
      console.error("Error casting vote", error);
    }

    setLoading(false);
  };

  const handlePickRandomVoter = async () => {
    setLoading(true);

    try {
      const randomVoter =
        await votingContract.getRandomVoterFromHighestVotedChoice();
      setRandomVoter(randomVoter);
    } catch (error) {
      console.error("Error picking random voter", error);
    }

    setLoading(false);
  };

  return (
    <div>
      <h1>Electronic Voting Application</h1>

      <h2>Choices:</h2>
      {choices.map((choice, index) => (
        <div key={index}>
          <span>{choice}</span>
          <button onClick={() => handleVote(index)}>Vote</button>
        </div>
      ))}

      <h2>Voting Results:</h2>
      <p>Total Votes: {voteCount}</p>
      {votedChoice && <p>Your Voted Choice: {votedChoice}</p>}

      <h2>Random Voter:</h2>
      {randomVoter && <p>{randomVoter} is the lucky winner!</p>}

      {loading && <p>Loading...</p>}

      <button onClick={handlePickRandomVoter}>Pick Random Voter</button>
    </div>
  );
};

export default App;
