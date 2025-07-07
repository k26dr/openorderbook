
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract OrderBook {
        enum Side { BUY, SELL }
        struct Order {
		address user;
                uint baseQuantity;
                uint quoteQuantity;
                uint orderId;
                uint nextOrderId;
                uint previousOrderId;
                address baseToken;
                address quoteToken;
                Side side;
        }
        mapping(uint => Order) orders;
        mapping(address => mapping(address => mapping(Side => uint))) orderbooks;
        uint orderCounter = 0;

	event OrderPlaced(uint orderId, address indexed user, address indexed baseToken, address indexed quoteToken, Side side, uint baseQuantity, uint quoteQuantity);
	event OrderCanceled(uint indexed orderId);
	event OrderFill(uint indexed orderId, uint baseQuantity);

        function placeOrder (address baseToken, address quoteToken, Side side, uint baseQuantity, uint quoteQuantity) public {
		if (side == Side.SELL) {
			IERC20(baseToken).transferFrom(msg.sender, address(this), baseQuantity);
		}
		else if (side == Side.BUY) {
			IERC20(quoteToken).transferFrom(msg.sender, address(this), quoteQuantity);
		}
                uint orderId = ++orderCounter;
                orders[orderId] = Order(msg.sender, baseQuantity, quoteQuantity, orderId, orderbooks[baseToken][quoteToken][side], 0, baseToken, quoteToken, side);
                orders[orderbooks[baseToken][quoteToken][side]].previousOrderId = orderId;
                orderbooks[baseToken][quoteToken][side] = orderId;
		emit OrderPlaced(orderId, msg.sender, baseToken, quoteToken, side, baseQuantity, quoteQuantity);
        }

        function cancelOrder (uint orderId) public {
                Order memory order = orders[orderId];
		require(msg.sender == order.user, "users can only cancel their own order");
                if (order.previousOrderId == 0) {
                        orderbooks[order.baseToken][order.quoteToken][order.side] = order.nextOrderId;
                }
                else {
                        orders[order.previousOrderId].nextOrderId = order.nextOrderId;
                }
                delete orders[orderId];
		if (order.side == Side.SELL) {
			IERC20(order.baseToken).transfer(msg.sender, order.baseQuantity);
		}
		else if (order.side == Side.BUY) {
			IERC20(order.quoteToken).transfer(msg.sender, order.quoteQuantity);
		}
		emit OrderCanceled(orderId);
        }
	
	function fillOrder (uint orderId, uint baseQuantity) public {
                Order memory order = orders[orderId];
		uint quoteQuantity = baseQuantity * order.quoteQuantity / order.baseQuantity;
		orders[orderId].baseQuantity -= baseQuantity;
		orders[orderId].quoteQuantity -= quoteQuantity;
		if (orders[orderId].baseQuantity == 0) {
			if (order.previousOrderId == 0) {
				orderbooks[order.baseToken][order.quoteToken][order.side] = order.nextOrderId;
			}
			else {
				orders[order.previousOrderId].nextOrderId = order.nextOrderId;
			}
			delete orders[orderId];
		}
		if (order.side == Side.SELL) {
			IERC20(order.quoteToken).transferFrom(msg.sender, order.user, quoteQuantity);
			IERC20(order.baseToken).transferFrom(address(this), msg.sender, baseQuantity);
		}
		else if (order.side == Side.BUY) {
			IERC20(order.baseToken).transferFrom(msg.sender, order.user, baseQuantity);
			IERC20(order.quoteToken).transferFrom(address(this), msg.sender, quoteQuantity);
		}
		emit OrderFill(orderId, baseQuantity);
	}

	// baseQuantity < dust will be ignored
        function getOpenOrders (address baseToken, address quoteToken, Side side, uint dust) public view returns (Order[] memory) {
                uint counter = 0;
                uint currentOrderId = orderbooks[baseToken][quoteToken][side];
                while (currentOrderId != 0) {
			if (orders[currentOrderId].baseQuantity >= dust) {
				counter++;
			}
                        currentOrderId = orders[currentOrderId].nextOrderId;
                }
                Order[] memory openOrders = new Order[](counter);

                currentOrderId = orderbooks[baseToken][quoteToken][side];
                counter = 0;
                while (currentOrderId != 0) {
			if (orders[currentOrderId].baseQuantity >= dust) {
				openOrders[counter] = orders[currentOrderId];
				counter++;
			}
                        currentOrderId = orders[currentOrderId].nextOrderId;
                }
                return openOrders;
        }
}

