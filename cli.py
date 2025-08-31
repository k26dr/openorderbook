from web3 import Web3
import os
import sys

rpcurl = os.environ['ETH_RPC_URL'] if "ETH_RPC_URL" in os.environ else "http://localhost:8545"
w3 = Web3(Web3.HTTPProvider(rpcurl))

try:
	command = sys.argv[1]
except:
	print("Error: Missing command")
	sys.exit(1)

if command == "placeorder":
	base_token = sys.argv[2]
	quote_token = sys.argv[3]
	side = sys.argv[4]
	base_quantity = sys.argv[5]
	price = sys.argv[6]

elif command == "cancelorder":
	orderid = sys.argv[2]
	
elif command == "fillorder":
	orderid = sys.argv[2]
	base_quantity = sys.argv[3]
else:
	print("Error: unrecognized command " + sys.argv[1])

