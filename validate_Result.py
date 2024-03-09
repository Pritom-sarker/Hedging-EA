balance = 100
baseRisk = 2
pf = [0.40,0.80, 0.40 ,0.80]
additinonalMuliplier = [1,1.5, 1.2,1.5]
fee = 0
dropdown = 0


# order - 1
val = (balance * baseRisk)/100
order1 = (val * additinonalMuliplier[0]) + (dropdown * fee)
print("order - 1: ", order1)
print("loss will be -> ", 0)
print("If Profit : ", order1 * pf[0]) 
print('--------------')
# order - 2
val = (order1 * (1/pf[1]) ) 
order2 = (val * additinonalMuliplier[1])  + (dropdown * fee)
print("order - 2: ", order2)
print("loss will be -> ", order1)
print("If Profit : ", (order2 * pf[1])-order1) 
print('--------------')
 
 # order - 3
val = (order2 * (1/pf[2]) ) - (order1 * pf[0]) 
order3 = (val * additinonalMuliplier[2])  + (dropdown * fee)
print("order - 3: ", order3)
print("loss will be -> ", (order2))
print("If Profit : ", (order3 * pf[2])+(order1*pf[0]) - (order2))
print('--------------')

 
 # order - 4
val = ((order3 * (1/pf[2]) ) + (order1 * (1/pf[0]))) - (order2 ) 
order4 = (val * additinonalMuliplier[3])  + (dropdown * fee)
print("order - 4: ", order4)
print("loss will be -> ", (order1 + order3))
print("If Profit : ", ((order4 * pf[3])+(order2*pf[1]) ) - (order1 + order3))
print('--------------')


print('Overall We Put: ', order1 + order2 + order3  +  order4)
print('IF its a loss: ', ((order1 * pf[0])+(order3*pf[2]) ) - (order2 + order4))


