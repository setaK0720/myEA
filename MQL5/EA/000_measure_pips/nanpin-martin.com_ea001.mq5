//+------------------------------------------------------------------+
//|                                                nanpin-martin.mq5 |
//|                               Copyright 2022,  nanpin-martin.com |
//|                                    https://www.nanpin-martin.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, nanpin-martin.com"
#property link "https://nanpin-martin.com/"

input double first_lot = 0.01;//初期ロット
input double nanpin_range = 1600;//ナンピン幅
input double martin_lot = 1.6; //マーチンロット
input double profit_target = 500;//利益目標
input int magic_number = 10001;//マジックナンバー
double slippage = 10;//スリッページ

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   int buy_position = 0;//buyポジション数
   int sell_position = 0;//sellポジション数
   double buy_profit = 0.0;//buyポジションの含み損益
   double sell_profit = 0.0;//sellポジションの含み損益
   double current_buy_lot = 0.0;//最新のbuyポジションのロット数
   double current_sell_lot = 0.0;//最新のsellポジションのロット数
   double current_buy_price = 0.0;//最新のbuyポジションの価格
   double current_sell_price = 0.0;//最新のsellポジションの価格

   Print(Point());

//+----ポジションの確認----------------------------------------+

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(PositionGetSymbol(i)!="")
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
           {
            buy_position++;
            buy_profit += PositionGetDouble(POSITION_PROFIT);
            current_buy_lot = PositionGetDouble(POSITION_VOLUME);
            current_buy_price = PositionGetDouble(POSITION_PRICE_OPEN);
           }
         else
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
              {
               sell_position++;
               sell_profit += PositionGetDouble(POSITION_PROFIT);
               current_sell_lot = PositionGetDouble(POSITION_VOLUME);
               current_sell_price = PositionGetDouble(POSITION_PRICE_OPEN);
              }
        }
     }

//+---------------------------------------------------------+　

//+----最新ティックの取得----------------------------------------+

   MqlTick last_tick;
   SymbolInfoTick(_Symbol,last_tick);

   double Ask=last_tick.ask;
   double Bid=last_tick.bid;

//+---------------------------------------------------------+

//+----新規エントリー注文----------------------------------------+

   if(buy_position == 0)
     {

      MqlTradeRequest request = {};
      MqlTradeResult result = {};

      request.action = TRADE_ACTION_DEAL; // 成行注文
      request.type = ORDER_TYPE_BUY; // 注文タイプ
      request.magic = magic_number; // マジックナンバー
      request.symbol = Symbol(); // 通貨ペア名
      request.volume = first_lot; // ロット数
      request.price = Ask; // 注文価格
      request.deviation = slippage; // スリッページ
      request.comment = "first_buy"; // コメント
      request.type_filling = ORDER_FILLING_IOC; // ボリューム実行ポリシー

      OrderSend(request, result);

     }
   if(sell_position == 0)
     {

      MqlTradeRequest request = {};
      MqlTradeResult result = {};

      request.action = TRADE_ACTION_DEAL;// 成行注文
      request.type = ORDER_TYPE_SELL; // 注文タイプ
      request.magic = magic_number; // マジックナンバー
      request.symbol = Symbol(); // 通貨ペア名
      request.volume = first_lot; // ロット数
      request.price = Bid;// 注文価格
      request.deviation = slippage; // スリッページ
      request.comment = "first_sell"; // コメント
      request.type_filling = ORDER_FILLING_IOC; // ボリューム実行ポリシー

      OrderSend(request, result);

     }

//+------------------------------------------------------------------+

//+----追加エントリー（ナンピン）注文----------------------------------------+

   if(buy_position > 0)
     {
      if(Ask < (current_buy_price - (nanpin_range * Point())))  //現在価格がナンピン幅に達しているか
        {

         MqlTradeRequest request = {};
         MqlTradeResult result = {};

         request.action = TRADE_ACTION_DEAL; // 成行注文
         request.type = ORDER_TYPE_BUY;  // 注文タイプ
         request.magic = magic_number; // マジックナンバー
         request.symbol = Symbol(); // 通貨ペア名
         request.volume = round(current_buy_lot*martin_lot*100)/100; // ロット数
         request.price = Ask; // 注文価格
         request.deviation = slippage; // スリッページ
         request.comment = "nanpin_buy"; // コメント
         request.type_filling = ORDER_FILLING_IOC; // ボリューム実行ポリシー

         OrderSend(request, result);

        }

     }


   if(sell_position > 0)
     {
      if(Bid > (current_sell_price + (nanpin_range * Point())))  //現在価格がナンピン幅に達しているか
        {

         MqlTradeRequest request = {};
         MqlTradeResult result = {};

         request.action = TRADE_ACTION_DEAL; // 成行注文
         request.type = ORDER_TYPE_SELL; // 注文タイプ
         request.magic = magic_number; // マジックナンバー
         request.symbol = Symbol();              // 通貨ペア名
         request.volume = round(current_sell_lot*martin_lot*100)/100; // ロット数
         request.price = Bid; // 注文価格
         request.deviation = slippage; // スリッページ
         request.comment = "nanpin_sell"; // コメント
         request.type_filling = ORDER_FILLING_IOC; // ボリューム実行ポリシー

         OrderSend(request, result);

        }
     }

//+------------------------------------------------------------------+

//+----ポジションクローズ注文----------------------------------------------+

   if(buy_position>0&&Ask>(position_average_price(POSITION_TYPE_BUY) + (profit_target * Point())))
     {
      buyClose();//すべてbuyポジションをクローズ
     }

   if(sell_position>0&&Bid<(position_average_price(POSITION_TYPE_SELL) - (profit_target * Point())))
     {
      sellClose();//すべてsellポジションをクローズ
     }

//+------------------------------------------------------------------+

  }
//+------------------------------------------------------------------+
//|   buyポジションをクローズする関数                                         |
//+------------------------------------------------------------------+
void buyClose()
  {

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(PositionGetSymbol(i)!="")
        {
         if(PositionGetInteger(POSITION_MAGIC)==magic_number)
           {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
              {

               MqlTradeRequest request = {};
               MqlTradeResult result = {};

               request.position =PositionGetTicket(i); // ポジションチケット
               request.action = TRADE_ACTION_DEAL; // 成行注文
               request.type = ORDER_TYPE_SELL; // 注文タイプ
               request.magic = magic_number; // マジックナンバー
               request.symbol = Symbol(); // 通貨ペア名
               request.volume = PositionGetDouble(POSITION_VOLUME); // ロット数
               request.price = SymbolInfoDouble(_Symbol,SYMBOL_BID); // 注文価格
               request.deviation = slippage; // スリッページ
               request.type_filling = ORDER_FILLING_IOC; // ボリューム実行ポリシー

               OrderSend(request, result);


              }
           }
        }
     }
  }


//+------------------------------------------------------------------+
//|   sellポジションをクローズする関数                                        |
//+------------------------------------------------------------------+
void sellClose()
  {

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(PositionGetSymbol(i)!="")
        {
         if(PositionGetInteger(POSITION_MAGIC)==magic_number)
           {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
              {

               MqlTradeRequest request = {};
               MqlTradeResult result = {};

               request.position =PositionGetTicket(i); // ポジションチケット
               request.action = TRADE_ACTION_DEAL;// 成行注文
               request.type = ORDER_TYPE_BUY;             // 注文タイプ
               request.magic = magic_number;             // マジックナンバー
               request.symbol = Symbol();              // 通貨ペア名
               request.volume = PositionGetDouble(POSITION_VOLUME);              // ロット数
               request.price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);// 注文価格
               request.deviation = slippage;               // スリッページ
               request.type_filling = ORDER_FILLING_IOC; // ボリューム実行ポリシー

               OrderSend(request, result);


              }

           }
        }
     }
  }

//+----pipsを価格に変換する関数----------------------------------------------------+

double PipsToPrice(double pips)
  {
    double price =0;

    int digits = Digits();

    // 3桁・5桁のFXブローカー
    if(digits == 3 || digits == 5){
      price = pips / MathPow(10, digits) * 10;
    }
    // 2桁・4桁のFXブローカー
    if(digits == 2 || digits == 4){
      price = pips / MathPow(10, digits);
    }
    // 価格を有効桁数で丸める
    price = NormalizeDouble(price, digits);
    return(price);
  }
//+------------------------------------------------------------------+

//+------平均取得単価計算-------------------------------------------------+

double position_average_price(int side)
{
   double lots_sum = 0;
   double price_sum = 0;
   double average_price = 0;
   
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if("" != PositionGetSymbol(i))
      {
         if(PositionGetInteger(POSITION_TYPE)==side)
         {
            if(Symbol()==PositionGetString(POSITION_SYMBOL))
            {
               if(PositionGetInteger(POSITION_MAGIC)==magic_number)
               {
                  lots_sum += PositionGetDouble(POSITION_VOLUME);
                  price_sum += PositionGetDouble(POSITION_PRICE_OPEN) * PositionGetDouble(POSITION_VOLUME);
               }
            }
         }
      }
   }
   
   if(lots_sum > 0)
   {
      average_price = price_sum / lots_sum;
   }

   return NormalizeDouble(average_price, _Digits);
}