contract OrderBook {
	enum Side { BUY, SELL }
	struct Order {
		uint price;
		uint quantity;
		uint orderId;
		uint nextOrderId;
		address baseToken;
		address quoteToken;
	}
	mapping(uint => Order) orders;    
	mapping(address => mapping(address => mapping(Side => uint)) orderbooks;
	uint orderCounter = 0;
	
	function placeOrder (address baseToken, address quoteToken, Side side, uint price, uint quantity) {
		uint orderId = ++orderCounter;
		orders[orderId] = Order(price, quantity, orderbooks[baseToken][quoteToken][side]);
		orderbooks[baseToken][quoteToken][side] = orderId;
	}

	function cancelOrder (uint orderId) {
		delete orders[orderId];
	}

	function getOpenOrders (address baseToken, address quoteToken, Side side) {
	}
}
