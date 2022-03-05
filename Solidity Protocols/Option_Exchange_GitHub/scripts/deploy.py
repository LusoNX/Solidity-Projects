from brownie import accounts,config,OptionExchange, ERC20, network
#TEHTER 0xd92e713d051c37ebb2561803a3b5fbabc4962431
#// FOS: 0x8B3634F4f8bffc7b7c8761aDe5410C6cAff3fec6

def deploy_option_exchange():
    sell_token = "0x8B3634F4f8bffc7b7c8761aDe5410C6cAff3fec6" ## Change here
    strike = 100
    premium = 10
    timestamp = 1677420535
    token_sold = 35

    # Get test accounts
    account = get_account()
    account_buyer = accounts.add(config["wallets"]["from_keys_2"])

    # Deploy the OptionExchange
    option_exchange = OptionExchange.deploy(account,sell_token,sell_token,"THETER","FOS",{"from":account}) # Deploy do contracto usando a conta derivada na linha acima
    print("------------------HERE-------------------------")
    print(option_exchange)
    print("------------------HERE-------------------------")

    # View function to check contract status
    option_summary = option_exchange.getShowSummary()
    print(option_summary)

    # Write the option 
    token = ERC20.at(sell_token)
    approve_func = token.approve(option_exchange.address,token_sold*10**18, {"from":account})
    transfer_func = token.transfer(option_exchange.address,token_sold*10**18,{"from":account})
    option_write = option_exchange.writeOption(strike,premium,timestamp,token_sold,{"from":account})

    ## Buy option 
    # Copy the contract, and confirm that the account is the owner of the option
    approve_buy = token.approve(option_exchange,premium*10**18,{"from":account_buyer})
    transfer_buy = token.transfer(account,premium*10**18,{"from":account_buyer})
    buy_opt = option_exchange.buyOption({"from":account_buyer})


    ## Exercise Option
    approve_exercise = token.approve(option_exchange,strike*10**18,{"from":account_buyer})
    aprrove_exercise_ac = token.transfer(option_exchange,strike*10**18,{"from":account_buyer})
    exercise_opt = option_exchange.exercise({"from":account_buyer})

def get_account():
    if(network.show_active() =="development"):
        return accounts[0]
    else:
        return accounts.add(config["wallets"]["from_keys"])


    # Transact

def main():
    deploy_option_exchange()

