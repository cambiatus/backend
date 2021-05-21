# Table of Contents
- **[Architecture Overview](#Architecture-Overview)**
- **[Flow of cambiatus data](#Flow-of-cambiatus-data)**
  - **[Creating a new community](#Creating-a-new-community)**
  - **[Updating community](#Updating-community)**
- **[Resources](#Resources)**

# Architecture Overview
Cambiatus is a DApp (decentralized application) that leverages the [EOS](https://training.eos.io/) blockchain protocol. Here are a few resources to checkout if you are new to DApp, [What is a Dapp](https://www.freecodecamp.org/news/what-is-a-dapp-a-guide-to-ethereum-dapps/), [A Dapp is not a protocol](https://medium.com/proof-systems/a-dapp-is-not-a-protocol-824411a55582).
Even though blockchain brings many benefits to an applicaiton it also has its limitations. The major limitation of blockchain is the ability to query and fetch data in a timely manner. In order to over come this limitation we took a hybrid approach: we store all data on the blockchain and replicate partial data on a traditional database. With this approach we gain the benefits of blockchain - security and immutability of our data - and the benefits of traditional databases - efficient and user friendly retrieval of data.

Here is an overview of the architecutre. We'll go more into detail in the next section.

<img src='https://lucid.app/publicSegments/view/7655c9e8-d9ad-4d1f-8da1-46a110e255e4/image.png' height='400' alt='Cambiatus Data Flow' />

# Flow of cambiatus data 
In this section we'll explore how our data flows through our application. Here are the objectives for this section:

* Understand the interaction between frontend and blockchain
* Transferring of data from blockchain to database
* Retrival and displaying of the data

When learning a new concept it's always great to use aexamples, so we'll walkthrough two use cases:
- **[Creating a new community](#Creating-a-new-community)**
- **[Updating community](#Updating-community)**

## Creating a new community
Our [frontend](https://github.com/cambiatus/frontend) is a static application built using Elm; the frontend sends *transactions* and triggers *actions* on the blockchain using [eosjs](https://github.com/EOSIO/eosjs) library. 

#### Difference between action and transaction?
Here is a great explaintation of what action and transcation mean in context of EOS:
> "An action is a unit of code to be executed inside a transaction. A transaction is a set of one or more actions which will execute or fail completely." [source](https://forum.ivanontech.com/t/reading-assignment-eos-basics/3085/6)

### Sending action
Let's say we want to create a new community identified by the symbol `0,TST`. In order to do so we need to do the following steps:

1. Compose a transaction for the `create` community `action`
2. Sign and send the transaction to the blockchain

A transaction has the following structure
```
{
  account: "cambiatus.cm",
  name: "create",
  authorization: [{ actor: "janedoe", permission: "active" }],
  data: {
    cmm_asset: "0 TST",
    creator: "janedoe12334",
    name: "TESTCOM",
    description: "A test community"
  }
}
```

* **account** - The account that is associated to the blockchain. It's either `cambiatus.cm` or `cambiatus.tk`, depending on if your transaction is related to a community (.cm) or a token (.tk).
* **name** - is the action you want to perform.
* **authorization** - A mapping of an actor and their permission level. Permission define what actions an actor can perform on the blockchain.
* **data** - set of data required by the action. Smart contracts define actions and their arguments, for example you can review all `ACTION` defined by our [community](https://github.com/cambiatus/contracts/blob/57b0fc896f8d710f774d5b5f862bc33c0fe4a890/community/community.hpp#L165) and [token](https://github.com/cambiatus/contracts/blob/57b0fc896f8d710f774d5b5f862bc33c0fe4a890/token/token.hpp#L50) contracts.

The code that sends the action to the blockchain can be [found here](https://github.com/cambiatus/frontend/blob/16908faf461329c2f165c0bd47ca69aa7371a95e/src/index.js#L450)

#### Available Community and Token actions
Click on the website below and click on the `contract` tab to see what actions and datas are available for `cambiatus.cm` or `cambiatus.tk`. 
* [cambiatus.cm](https://local.bloks.io/account/cambiatus.cm?nodeUrl=http%3A%2F%2Fstaging.cambiatus.io&coreSymbol=SYS&systemDomain=eosio&loadContract=true&tab=Tables&account=cambiatus.cm&scope=cambiatus.cm&limit=100)
* [cambiatus.tk](https://local.bloks.io/account/cambiatus.tk?nodeUrl=http%3A%2F%2Fstaging.cambiatus.io&coreSymbol=SYS&systemDomain=eosio)

### Adding new block to the blockchain
Once the transaction has been pushed to the blockchain then it would get verified and added to the blockchain. The diagram below demonstrates the process of adding a block to EOS blockchain.

![Block addition to EOS blockchain](https://raw.githubusercontent.com/cambiatus/backend/architecture-deep-dive/.github/block_addition.png)

### Emitting new blocks to the database
The new community has been added to the blockchain! However, we sill need to send the data to our database so our frontend could fetch and display it to the user. We can accompolish this by leveraging an event driven library developed by EOS called [demux-js](https://github.com/EOSIO/demux-js-eos).

#### How demux-js works
1. The `Action Reader` listens for any changes in blockchain. When it detects a change it will pass the data to the `Action Watcher`.
2. `Action Watcher` triggers the `Action Handler`, which in turn updates our database with the data retrieved from the blockchain.

### Updating frontend with the new data
Once an action has been pushed to the blockchain, we *optimistically assume* that data has trickled down to our database. The current method is very unreliable for querying for the data; however, we are looking to leverage Graphql subscription for this [see here](https://github.com/cambiatus/backend/issues/148).

## Updating community
The process for updating a community is similar to **[creating a new community](#Creating-a-new-community)** the only difference is how we react once we have pushed the transaction to the blockchain.

After we push a transaction, on a successful operation we receive a `transactionId`, which indicates that our data has been added to the blockchain. 

Or our transaction can fail. It can fail for two reasons:
1. Invalid permission
2. Missing/invalid data passed

# Resources
1. [Overview of demux-js](https://medium.com/eosio/introducing-demux-deterministic-databases-off-chain-verified-by-the-eosio-blockchain-bd860c49b017)
2. [Overview of EOS](https://training.eos.io/courses/introduction-to-eosio-non-technical) 
