# Table of Contents

# Application Overview
Cambiatus is a DApp (decentralized application) that leverags [EOS](https://training.eos.io/) blockchain protocol, here are few resource to checkout if you are new to DApp, [[1]](https://www.freecodecamp.org/news/what-is-a-dapp-a-guide-to-ethereum-dapps/), [[2]](https://medium.com/proof-systems/a-dapp-is-not-a-protocol-824411a55582).

Even though blockchain brings many benefits to an applicaiton it also has its limitations. The major limitation of blockchain is the ability to query and fetch data in a timely manner. In order to over come this limitation we utilize a hybrid: we store all data on the blockchain and replicate partial data on a traditional database. With this approach we gain the benefits of blockchain - security and immutable of our data; efficient and user friendly retrival of our data from a traditional database.

Here is an overview of the architecutre. We'll go more into detail in the next section.

<img src='https://i.imgur.com/MFfGOe3.png' height='492' alt='Cambiatus Data Flow' />

# Lifecycle
In this section we'll explore our architecture in more detail. Here are the objectives for this section:
* Understand the interaction between frontend and blockchain
* The transferring of data from blockchain to the database
* Retrival and displaying of the data

When learning a new concept it's always great to walkthrough an example. By doing so it will connect abstract ideas to implementation. For this section and future ones we'll use the example of *creating a new community*.

## Frontend interaction with the blockchain
Our [frontend](https://github.com/cambiatus/frontend) is a static application built using Elm; the frontend sends *transactions* and triggers *actions* on the blockchain using [eosjs](https://github.com/EOSIO/eosjs) library. 

#### Difference between action and transaction?
Here is a great explaintation of what action and transcation is in EOS: "An action is a unity of code to be executed inside a transaction. A transaction is a set of one or more actions which will execute or fail completely. A transaction cannot execute partially." [source](https://forum.ivanontech.com/t/reading-assignment-eos-basics/3085/6)

### Creating a new community
Let's say we want to create a new community called `0,TST`. In order to do so we need to do the following steps:
1. Compose a transaction data
2. Sign and send the transaction to the blockchain

A transaction data has the following structure

```
{
  account: "cambiatus.cm",
  name: "create",
  authorization: [{ actor: "henriquebuss", permission: "active" }],
  data: {
    cmm_asset: 0 TST
    creator: janedoe12334
    name: TESTCOM
    description: A test community
  }
}
```
* Account is either cambiatus.cm or cambiatus.tk, depending on if your transaction is related to a community (.cm) or a token (.tk).
* Name is the actual name of the transaction/action you want to perform (it's scoped to the account)
* Authorization just says what user is doing the transaction (it's the accountname on our app)

#### Difference between community and token


You can see what data each transaction needs on the [contracts repo](https://github.com/cambiatus/contracts). There are contracts for community and token (these are the name of the directories on the repo), and you can open the .hpp file under those directories and look at the ACTIONs to see what's available and what each one needs

After we push a transaction, we just get a transactionId back, not the community, so we have two options:
If the data we're dealing with doesn't have any "computed" fields (such as a new id), we can assume the data we sent is valid, so we don't need anything back from the backend. This happens when we're just updating a community, for example
If we do need some computed field, such as when the user creates a new action (which will have a new id), we don't really have a reliable solution right now. We just reload the page, query the backend again and hope the transaction is there already. Good news is @Lucca thinks we can create a Graphql subscription for this (see here)

You can also see the available actions on the blockchain through bloks:
community
 token
Just go to the Contract tab, and then you can see the Tables, Actions and ABI


2. Transactions is verified and added to blockchain

3. Event source is notified of the update
Action reader listens for updated data in blockchain. Passes the data to Action watchter.

4. Event source updates database with the new data
Action watcher sends the parsed data to action handler which pushes the data to the database

5. Frontend queries for updated data
The frontend queries for the update data and displays the result

## Creating Community



## Pushing Community to EOS Blockchain

## Querying and Displaying Community

# Resources
* https://medium.com/eosio/introducing-demux-deterministic-databases-off-chain-verified-by-the-eosio-blockchain-bd860c49b017

