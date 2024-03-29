//+------------------------------------------------------------------+
//|                                                nanpin-martin.mq4 |
//|                         `      Copyright 2022, nanpin-martin.com |
//|                                      "https://nanpin-martin.com/ |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2022, nanpin-martin.com"
#property link        "https://nanpin-martin.com/"


//+------------------------------------------------------------------+
//| Inputの設定                                                       |
//+------------------------------------------------------------------+

input double first_lot = 0.01;//初期ロット
input double nanpin_range = 160;//ナンピン幅
input double profit_pips_target = 50;//利益目標pips
input int magic_number = 10001; //マジックナンバー
static int ticket_number;//チケットナンバー
double slippage = 10;//スリッページ
input double lot_type = 1.85; //lot倍率
input int spread_limit = 450; //スプレッド上限
input bool time_limit = false;//エントリー時間制限（true：あり、false：なし）
input string start_time = "00:00";//エントリー開始時間
input string end_time = "15:00";//エントリー終了時間
input bool forced_close = false;//強制クローズ（true：あり、false：なし）
input int position_limit = 12; //最大ポジション数（片側）

//+------------------------------------------------------------------+
//| ループ処理                                                         |
//+------------------------------------------------------------------+
void OnTick()
  {

//+----変数の定義-----------------------------------------------------+

   int cnt;
   int current_buy_position;//最新のbuyポジション
   int current_sell_position;//最新のsellポジション
   int buy_position;//buyポジション数
   int sell_position;//sellポジション数
   double buy_profit;//buyポジションの含み損益
   double sell_profit;//sellポジションの含み損益
   bool entry_flag;//エントリーフラグ
   bool close_flag;//クローズフラグ

//+----エントリー時間帯の確認---------------------------------------------+

   entry_flag=false; //エントリーフラグの初期化
   close_flag=false; //クローズフラグの初期化

   if(!time_limit && MarketInfo(Symbol(),MODE_SPREAD)< spread_limit){ //エントリー時間制限なし(false)の場合
      entry_flag=true;
   }else
   if(entryTime(start_time,end_time) && MarketInfo(Symbol(),MODE_SPREAD)< spread_limit){ //エントリー時間内(true)の場合
      entry_flag=true;
   }else
   if(forced_close){ //強制クローズあり(true)の場合
      allClose(GreenYellow);
   }



//+----ポジションの確認--------------------------------------------------+

   buy_position=0;//buyポジション数の初期化
   sell_position=0;//sellポジション数の初期化
   current_buy_position=-1;//最新buyポジションの初期化
   current_sell_position=-1;//最新sellポジションの初期化

   for(cnt=0;cnt<OrdersTotal();cnt++)//ポジションの確認
   {
    if(OrderSelect(cnt,SELECT_BY_POS)==false)continue;
    if(OrderMagicNumber()!=magic_number)continue;
    if(OrderType()==OP_BUY)
     {
      current_buy_position=cnt;
      buy_position+=1;
      buy_profit=buy_profit+OrderProfit();
   
     };//buyポジションの確認

    if(OrderType()==OP_SELL)
     {
      current_sell_position=cnt;
      sell_position+=1;
      sell_profit=sell_profit+OrderProfit();

     };//sellポジションの確認
   }

//+------------------------------------------------------------------+


//+----新規エントリー注文------------------------------------------------+ 

   if(buy_position==0&&entry_flag&&iCustom(Symbol(),Period(),"SHI_Channel_Fast",0,1) > 0)//buyポジションを持っていない場合
   {
     ticket_number=OrderSend(
                             Symbol(), //通貨ペア
                             OP_BUY, //buy:OP_BUY, sell:OP_SELL
                             first_lot, //ロット数
                             Ask, //注文価格
                             slippage, //スリッページ
                             0,  //決済逆指値
                             0,  //決済指値
                             "first_buy",  //注文コメント
                             magic_number,  //マジックナンバー
                             0,  //注文の有効期限
                             Blue  //矢印の色
                             );
   }
   if(sell_position==0&&entry_flag)//sellポジションを持っていない場合
   {
     ticket_number=OrderSend(
                             Symbol(), //通貨ペア
                             OP_SELL,  //buy:OP_BUY, sell:OP_SELL
                             first_lot, //ロット数
                             Bid, //注文価格
                             slippage, //スリッページ
                             0,  //決済逆指値
                             0,  //決済指値
                             "first_sell",  //注文コメント
                             magic_number,  //マジックナンバー
                             0,  //注文の有効期限
                             Red  //矢印の色
                             );
   }

//+------------------------------------------------------------------+


//+----追加エントリー（ナンピン）注文----------------------------------------+

   if(buy_position>0 && buy_position < position_limit) //buyポジションを1つ以上持っている場合
   {
    OrderSelect(current_buy_position,SELECT_BY_POS); //最新のbuyポジションを選択
    if(Ask<(OrderOpenPrice()-nanpin_range*Point)) //現在価格がナンピン幅に達しているか
    {
      ticket_number=OrderSend(
                              Symbol(), //通貨ペア
                              OP_BUY,  //buy:OP_BUY, sell:OP_SELL
                              round(OrderLots()*lot_type*100)/100, //ロット数
                              Ask, //注文価格
                              slippage, //スリッページ
                              0,  //決済逆指値
                              0,  //決済指値
                              "nanpin_buy",  //注文コメント
                              magic_number,  //マジックナンバー
                              0,  //注文の有効期限
                              Blue  //矢印の色
                              );
     }
   }
   
   if(sell_position>0 && sell_position < position_limit) //sellポジションを1つ以上持っている場合
   {
     OrderSelect(current_sell_position,SELECT_BY_POS); //最新のsellポジションを選択
     if(Bid>(OrderOpenPrice()+nanpin_range*Point)) //現在価格がナンピン幅に達しているか
     { 
       ticket_number=OrderSend(
                              Symbol(), //通貨ペア
                              OP_SELL,  //buy:OP_BUY, sell:OP_SELL
                              round(OrderLots()*lot_type*100)/100, //ロット数
                              Bid, //注文価格
                              slippage, //スリッページ
                              0,  //決済逆指値
                              0,  //決済指値
                              "nanpin_sell",  //注文コメント
                              magic_number,  //マジックナンバー
                              0,  //注文の有効期限
                              Red  //矢印の色
                              );  
   
     }
    }

//+------------------------------------------------------------------+


//+----ポジションクローズ注文----------------------------------------------+

   if(buy_position>0&&position_average_buy_price() + PipsToPrice(profit_pips_target)<Bid)
   {
     buyClose(Red);//すべてbuyポジションをクローズ
   }
   
   if(sell_position>0&&position_average_sell_price() - PipsToPrice(profit_pips_target)>Ask)
   {
     sellClose(Blue);//すべてsellポジションをクローズ
   }

//+------------------------------------------------------------------+

}

//+------------------------------------------------------------------+
//| ループ処理おわり                                                     |
//+------------------------------------------------------------------+

//+----エントリー時間帯チェック-----------------------------------------------+

   bool entryTime(string stime,string etime){
      string startDate=TimeToStr(TimeCurrent(),TIME_DATE); //現在の年月日
      datetime startTime=StrToTime(startDate+" "+stime); //年月日＋開始時間
      datetime endTime=StrToTime(startDate+" "+etime); //年月日＋終了時間
      if(startTime<endTime){
         if(startTime<=TimeCurrent() && TimeCurrent()<endTime)return(true);
         else return(false); //現在時刻がエントリー時間内の場合、true
      }else{
         if(endTime<=TimeCurrent() && TimeCurrent()<startTime)return(false);
         else return(true); //現在時刻がエントリー時間外の場合、false
      }
      return(false);
   }

//+-----------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ポジションをクローズする関数                                              |
//+------------------------------------------------------------------+


//+----buyポジションをクローズする関数----------------------------------------+
void buyClose(color clr)
{
   int i;
   for(i=OrdersTotal()-1;i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)
         continue;
      if(OrderSymbol()!=Symbol()||OrderMagicNumber()!=magic_number)
         continue;
      if(OrderType()==OP_BUY)
         OrderClose(OrderTicket(),OrderLots(),Bid,NormalizeDouble(slippage,0),clr);
   }
}

//+------------------------------------------------------------------+


//+----sellポジションをクローズする関数---------------------------------------+
void sellClose(color clr)
{
   int i;
   for(i=OrdersTotal()-1;i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)
         continue;
      if(OrderSymbol()!=Symbol()||OrderMagicNumber()!=magic_number)
         continue;
      if(OrderType()==OP_SELL)
         OrderClose(OrderTicket(),OrderLots(),Ask,NormalizeDouble(slippage,0),clr);
   }
}

//+------------------------------------------------------------------+

//+----全てのポジションを決済する関数----------------------------------------------------+

void allClose(color clr)
{
   int i;
   for(i=OrdersTotal()-1;i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)
         continue;
      if(OrderSymbol()!=Symbol()||OrderMagicNumber()!=magic_number)
         continue;
      if(OrderType()==OP_BUY)
         OrderClose(OrderTicket(),OrderLots(),Bid,NormalizeDouble(slippage,0),clr);
      if(OrderType()==OP_SELL)
         OrderClose(OrderTicket(),OrderLots(),Ask,NormalizeDouble(slippage,0),clr);
   }
}

//+---------------------------------------------------------------------------------+

//+----pipsを価格に変換する関数----------------------------------------------------+

double PipsToPrice(double pips)
{
   double price = 0;

   // 現在の通貨ペアの小数点以下の桁数を取得
   int digits = (int)MarketInfo(Symbol(), MODE_DIGITS);

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

//+------平均取得単価計算(買い)-------------------------------------------------+

double position_average_buy_price()
  {
   double sum_buy_lot = 0;//buyポジション合計ロット
   double price_buy_sum = 0;//buy価格合計
   double average_buy_price = 0;//buy価格平均
 
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         if(OrderType() == OP_BUY)
           {
            if(OrderSymbol()==Symbol())
              {
               if(OrderMagicNumber()==10001)
                 {
                  sum_buy_lot += OrderLots();
                  price_buy_sum += OrderOpenPrice() * OrderLots();
                 }
              }
           }
        }
     }
   if(sum_buy_lot && price_buy_sum)
     {
      average_buy_price = price_buy_sum/sum_buy_lot;
     }
   return average_buy_price;
  }

//+------平均取得単価計算（売り）-------------------------------------------------+

double position_average_sell_price()
  {
   double sum_sell_lot = 0;//sellポジション合計ロット
   double price_sell_sum = 0;//sell価格合計
   double average_sell_price = 0;//sell価格平均
 
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         if(OrderType() == OP_SELL)
           {
            if(OrderSymbol()==Symbol())
              {
               if(OrderMagicNumber()==10001)
                 {
                  sum_sell_lot += OrderLots();
                  price_sell_sum += OrderOpenPrice() * OrderLots();
                 }
              }
           }
        }
     }
   if(sum_sell_lot && price_sell_sum)
     {
      average_sell_price = price_sell_sum/sum_sell_lot;
     }
   return average_sell_price;
  }