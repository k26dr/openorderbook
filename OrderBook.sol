contract OrderBook {
        enum Side { BUY, SELL }
        struct Order {
                uint price;
                uint quantity;
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

        function placeOrder (address baseToken, address quoteToken, Side side, uint price, uint quantity) public {
                uint orderId = ++orderCounter;
                orders[orderId] = Order(price, quantity, orderId, orderbooks[baseToken][quoteToken][side], 0, baseToken, quoteToken, side);
                orders[orderbooks[baseToken][quoteToken][side]].previousOrderId = orderId;
                orderbooks[baseToken][quoteToken][side] = orderId;
        }

        function cancelOrder (uint orderId) public {
                Order memory order = orders[orderId];
                if (order.previousOrderId == 0) {
                        orderbooks[order.baseToken][order.quoteToken][order.side] = order.nextOrderId;
                }
                else {
                        orders[order.previousOrderId].nextOrderId = order.nextOrderId;
                }
                delete orders[orderId];
        }

        function getOpenOrders (address baseToken, address quoteToken, Side side) public view returns (Order[] memory) {
                uint counter = 0;
                uint currentOrderId = orderbooks[baseToken][quoteToken][side];
                while (currentOrderId != 0) {
                        counter++;
                        currentOrderId = orders[currentOrderId].nextOrderId;
                }
                Order[] memory openOrders = new Order[](counter);

                currentOrderId = orderbooks[baseToken][quoteToken][side];
                counter = 0;
                while (currentOrderId != 0) {
                        openOrders[counter] = orders[currentOrderId];
                        counter++;
                        currentOrderId = orders[currentOrderId].nextOrderId;
                }
                return openOrders;
        }
}
