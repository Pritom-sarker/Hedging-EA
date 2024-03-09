import random

def trade(lossValue):

    buySide = []
    sellSide = []

    round = 2

    buySide.append(baseRisk  )

    for i in range((round*2)-1):
        if i%2 == 0:
            val = (sum(buySide) * (1/pf) ) - (sum(sellSide) * (pf)) 
            val = (val * additinonalMuliplier[i]) + (lossMult * lossValue )
            sellSide.append(val)
        else:
            val = (sum(sellSide) * (1/pf) ) - (sum(buySide) * (pf)) 
            val = (val * additinonalMuliplier[i]) + (lossMult * lossValue )
            buySide.append(val)

    # print(buySide, sellSide)
    tradeResult = []
    for i in range(round):
        bp = (sum(buySide[:i+1]) * pf) - sum(sellSide[:i])
        tradeResult.append([buySide[i],bp])
        sp = (sum(sellSide[:i+1]) * pf) - sum(buySide[:i+1])
        tradeResult.append([sellSide[i],sp])
        
    #     print('BUY Order {} : {} % -> Profit: {} %'.format(i+1,buySide[i],bp))
    #     print('SELL Order {} : {} % -> Profit: {} %'.format(i+1,sellSide[i],sp))

    # print('------------------------')
    bp = (sum(buySide) * pf) - sum(sellSide)
    # print('If Loss -> ', bp)
    tradeResult.append([0,-bp])
    return tradeResult
    
def generate_random_number():
    random_number = random.choices(numbers, probabilities)[0]
    return random_number

if __name__ == '__main__':
    # change it as you like 
    numberOfRound = 1000 # each time it will take 100 trades and then it will average out the result
    numberOfTrades = 100
    baseRisk = 2
    pf =0.5
    additinonalMuliplier = [1.5,0.5,0.5]
    probabilities = [0.4, 0.3, 0.1, 0.1, 0.1]  # Adjust probabilities as needed
    lossMult = 0.25
    
    # dont touch below variables
    balance = 100
    numbers = [0, 1, 2, 3, 4]
    maxBalance = 0
    marginCallCounter = 0
    totalres = []
    
    
    for rnd in range(numberOfRound):
        balance = 100
        maxBalance = 0
        for tr in range(numberOfTrades):
            if balance < 0:
                #print('Margin call!! ')
                marginCallCounter+=1
                balance = 0
                break
            num = generate_random_number()
            result = trade(abs(maxBalance - balance))
            if result[num][0] > balance:
                #print("Order Size -", result[num][0])
                marginCallCounter+=1
                balance = 0
                break
            balance+= result[num][1]
            if maxBalance < balance:
                maxBalance = balance
 
        totalres.append(balance)


print('Margin Call : ', marginCallCounter)
print('Max: ', max(totalres))
print('AVG: ', sum(totalres)/(len(totalres)-marginCallCounter))
    

