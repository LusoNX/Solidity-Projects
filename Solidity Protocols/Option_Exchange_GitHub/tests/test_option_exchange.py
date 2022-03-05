from brownie import accounts,config,OptionExchange, ERC20, network


def get_account():
    if(network.show_active() =="development"):
        return accounts[0]
    else:
        return accounts.add(config["wallets"]["from_keys"])


def test_deploy_1():
    value = 10**19
    sell_token = "0x8B3634F4f8bffc7b7c8761aDe5410C6cAff3fec6" ## Change here
    strike = 100
    premium = 10
    timestamp = 1677420535
    token_sold = 10

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
    approve_func = token.approve(option_exchange.address,value, {"from":account})
    transfer_func = token.transfer(option_exchange.address,value,{"from":account})
    option_write = option_exchange.writeOption(strike,premium,timestamp,token_sold,{"from":account})


    ## Buy option 
    # Copy the contract, and confirm that the account is the owner of the option
    approve_buy = token.approve(account,value,{"from":account_buyer})
    transfer_buy = token.transfer(account,value,{"from":account_buyer})
    buy_opt = option_exchange.buyOption({"from":account_buyer})


    ## Exercise the Option










